# frozen_string_literal: true
module Labels
  class AvailableLabelsService
    attr_reader :current_user, :parent, :params

    def initialize(current_user, parent, params)
      @current_user = current_user
      @parent = parent
      @params = params
    end

    def find_or_create_by_titles(key = :labels, find_only: false)
      labels = params.delete(key)

      return [] unless labels

      labels = labels.split(',').map(&:strip) if labels.is_a?(String)
      existing_labels = LabelsFinder.new(current_user, finder_params(labels)).execute.index_by(&:title)

      labels.map do |label_name|
        label = Labels::FindOrCreateService.new(
          current_user,
          parent,
          include_ancestor_groups: true,
          title: label_name,
          existing_labels_by_title: existing_labels
        ).execute(find_only: find_only)

        label
      end.compact
    end

    def filter_labels_ids_in_param(key)
      ids = Array.wrap(params[key])
      return [] if ids.empty?

      # rubocop:disable CodeReuse/ActiveRecord
      existing_ids = available_labels.id_in(ids).pluck(:id)
      # rubocop:enable CodeReuse/ActiveRecord
      ids.map(&:to_i) & existing_ids
    end

    def filter_locked_label_ids(ids)
      available_labels.with_lock_on_merge.id_in(ids).pluck(:id) # rubocop:disable CodeReuse/ActiveRecord
    end

    def available_labels
      @available_labels ||= LabelsFinder.new(current_user, finder_params).execute
    end

    private

    def finder_params(titles = nil)
      finder_params = { include_ancestor_groups: true }
      finder_params[:title] = titles if titles

      case parent
      when Group
        finder_params[:group_id] = parent.id
        finder_params[:only_group_labels] = true
      when Project
        finder_params[:project_id] = parent.id
      end

      finder_params
    end
  end
end
