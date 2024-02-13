# frozen_string_literal: true

module Projects
  module Ml
    class ModelVersionFinder
      include Gitlab::Utils::StrongMemoize
      include ValidOrDefault

      VALID_ORDER_BY = %w[version created_at id].freeze
      VALID_SORT = %w[asc desc].freeze

      def initialize(model, params = {})
        @model = model
        @params = params
      end

      def execute
        relation
      end

      private

      def relation
        @versions = ::Ml::ModelVersion.for_model(model).including_relations

        @versions = by_version
        ordered
      end
      strong_memoize_attr :relation

      def by_version
        return versions unless params[:version].present?

        versions.by_version(params[:version])
      end

      def ordered
        order_by = valid_or_default(params[:order_by]&.downcase, VALID_ORDER_BY, 'id')
        sort = valid_or_default(params[:sort]&.downcase, VALID_SORT, 'desc')

        return versions.order_by_version(sort) if order_by == 'version'

        versions.order_by("#{order_by}_#{sort}").with_order_id_desc
      end

      attr_reader :params, :model, :versions
    end
  end
end
