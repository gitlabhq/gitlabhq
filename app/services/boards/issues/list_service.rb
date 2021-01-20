# frozen_string_literal: true

module Boards
  module Issues
    class ListService < Boards::BaseItemsListService
      include Gitlab::Utils::StrongMemoize

      def self.valid_params
        IssuesFinder.valid_params
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def metadata
        issues = Issue.arel_table
        keys = metadata_fields.keys
        # TODO: eliminate need for SQL literal fragment
        columns = Arel.sql(metadata_fields.values_at(*keys).join(', '))
        results = Issue.where(id: items.select(issues[:id])).pluck(columns)

        Hash[keys.zip(results.flatten)]
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def ordered_items
        items.order_by_position_and_priority(with_cte: params[:search].present?)
      end

      def finder
        IssuesFinder.new(current_user, filter_params)
      end

      def board
        @board ||= parent.boards.find(params[:board_id])
      end

      def metadata_fields
        { size: 'COUNT(*)' }
      end

      def filter_params
        set_scope
        set_non_archived
        set_issue_types

        super
      end

      def set_scope
        params[:include_subgroups] = board.group_board?
      end

      def set_non_archived
        params[:non_archived] = parent.is_a?(Group)
      end

      def set_issue_types
        params[:issue_types] = Issue::TYPES_FOR_LIST
      end

      def item_model
        Issue
      end
    end
  end
end

Boards::Issues::ListService.prepend_if_ee('EE::Boards::Issues::ListService')
