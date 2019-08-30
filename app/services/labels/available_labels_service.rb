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

      labels = labels.split(',') if labels.is_a?(String)

      labels.map do |label_name|
        label = Labels::FindOrCreateService.new(
          current_user,
          parent,
          include_ancestor_groups: true,
          title: label_name.strip,
          available_labels: available_labels
        ).execute(find_only: find_only)

        label
      end.compact
    end

    def filter_labels_ids_in_param(key)
      return [] if params[key].to_a.empty?

      # rubocop:disable CodeReuse/ActiveRecord
      available_labels.by_ids(params[key]).pluck(:id)
      # rubocop:enable CodeReuse/ActiveRecord
    end

    private

    def available_labels
      @available_labels ||= LabelsFinder.new(current_user, finder_params).execute
    end

    def finder_params
      params = { include_ancestor_groups: true }

      case parent
      when Group
        params[:group_id] = parent.id
        params[:only_group_labels] = true
      when Project
        params[:project_id] = parent.id
      end

      params
    end
  end
end
