# frozen_string_literal: true

module Boards
  class BaseItemsListService < Boards::BaseService
    include Gitlab::Utils::StrongMemoize
    include ActiveRecord::ConnectionAdapters::Quoting

    def execute
      items = init_collection

      order(items)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def metadata(required_fields = [:issue_count, :total_issue_weight])
      fields = metadata_fields(required_fields)
      keys = fields.keys
      columns = fields.values_at(*keys)

      results = item_model
        .where(id: collection_ids)
        .pluck(*columns)
        .flatten

      Hash[keys.zip(results)]
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def collection_ids
      @collection_ids ||= init_collection.select(item_model.arel_table[:id])
    end

    def metadata_fields(required_fields)
      required_fields&.include?(:issue_count) ? { size: Arel.sql('COUNT(*)') } : {}
    end

    def order(items)
      raise NotImplementedError
    end

    def finder
      raise NotImplementedError
    end

    def board
      raise NotImplementedError
    end

    def item_model
      raise NotImplementedError
    end

    # We memoize the query here since the finder methods we use are quite complex. This does not memoize the result of the query.
    # rubocop: disable CodeReuse/ActiveRecord
    def init_collection
      strong_memoize(:init_collection) do
        filter(finder.execute).reorder(nil)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def filter(items)
      # when grouping board issues by epics (used in board swimlanes)
      # we need to get all issues in the board
      # TODO: ignore hidden columns -
      # https://gitlab.com/gitlab-org/gitlab/-/issues/233870
      return items if params[:all_lists]

      items = without_board_labels(items) unless list&.movable? || list&.closed?
      items = with_list_label(items) if list&.label?
      items
    end

    def list
      return unless params.key?(:id) || params.key?(:list)

      strong_memoize(:list) do
        id = params[:id]
        list = params[:list]

        if list.present?
          list
        elsif board.lists.loaded?
          board.lists.find { |l| l.id == id }
        else
          board.lists.find(id)
        end
      end
    end

    def filter_params
      set_parent
      set_state
      set_attempt_search_optimizations

      params
    end

    def set_parent
      if parent.is_a?(Group)
        params[:group_id] = parent.id
      else
        params[:project_id] = parent.id
      end
    end

    def set_state
      return if params[:all_lists]

      params[:state] = list && list.closed? ? 'closed' : 'opened'
    end

    def set_attempt_search_optimizations
      return unless params[:search].present?

      if board.group_board?
        params[:attempt_group_search_optimizations] = true
      else
        params[:attempt_project_search_optimizations] = true
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def board_label_ids
      @board_label_ids ||= board.lists.movable.pluck(:label_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def without_board_labels(items)
      return items unless board_label_ids.any?

      items.where(label_links(items, board_label_ids.compact).arel.exists.not)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def label_links(items, label_ids)
      labels_filter.label_link_query(items, label_ids: label_ids)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def with_list_label(items)
      items.where(label_links(items, [list.label_id]).arel.exists)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def labels_filter
      Issuables::LabelFilter.new(params: {}, project: project, group: group)
    end
    strong_memoize_attr :labels_filter

    def group
      parent if parent.is_a?(Group)
    end

    def project
      parent if parent.is_a?(Project)
    end
  end
end
