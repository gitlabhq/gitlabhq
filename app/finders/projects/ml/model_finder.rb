# frozen_string_literal: true

module Projects
  module Ml
    class ModelFinder
      include Gitlab::Utils::StrongMemoize

      VALID_ORDER_BY = %w[name created_at updated_at id].freeze
      VALID_SORT = %w[asc desc].freeze

      def initialize(project, params = {})
        @project = project
        @params = params
      end

      def execute
        relation
      end

      def count
        relation.length
      end

      private

      def relation
        @models = ::Ml::Model
            .by_project(project)
            .including_latest_version
            .including_project
            .with_version_count

        @models = by_name
        ordered
      end
      strong_memoize_attr :relation

      def by_name
        return models unless params[:name].present?

        models.by_name(params[:name])
      end

      def ordered
        order_by = valid_or_default(params[:order_by]&.downcase, VALID_ORDER_BY, 'created_at')
        sort = valid_or_default(params[:sort]&.downcase, VALID_SORT, 'desc')

        models.order_by("#{order_by}_#{sort}").with_order_id_desc
      end

      def valid_or_default(value, valid_values, default)
        return value if valid_values.include?(value)

        default
      end

      attr_reader :params, :project, :models
    end
  end
end
