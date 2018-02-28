module EE
  module IssuesFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    module ClassMethods
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

    def weights?
      params[:weight].present? && params[:weight] != ::Issue::WEIGHT_ALL
    end

    def filter_by_no_weight?
      params[:weight] == ::Issue::WEIGHT_NONE
    end

    def filter_by_any_weight?
      params[:weight] == ::Issue::WEIGHT_ANY
    end
  end
end
