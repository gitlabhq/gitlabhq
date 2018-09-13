module EE
  module IssuesFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    class_methods do
      extend ::Gitlab::Utils::Override

      override :scalar_params
      def scalar_params
        @scalar_params ||= super + [:weight]
      end
    end

    override :filter_items
    def filter_items(items)
      by_weight(super)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def by_weight(items)
      return items unless weights?

      if filter_by_no_weight?
        items.where(weight: [-1, nil])
      elsif filter_by_any_weight?
        items.where.not(weight: [-1, nil])
      else
        items.where(weight: params[:weight])
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def weights?
      params[:weight].present? && params[:weight] != ::Issue::WEIGHT_ALL
    end

    def filter_by_no_weight?
      params[:weight] == ::Issue::WEIGHT_NONE
    end

    def filter_by_any_weight?
      params[:weight] == ::Issue::WEIGHT_ANY
    end

    override :by_assignee
    def by_assignee(items)
      if assignees.any?
        assignees.each do |assignee|
          items = items.assigned_to(assignee)
        end

        return items
      end

      super
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def assignees
      strong_memoize(:assignees) do
        if params[:assignee_ids]
          ::User.where(id: params[:assignee_ids])
        elsif params[:assignee_username]
          ::User.where(username: params[:assignee_username])
        else
          []
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
