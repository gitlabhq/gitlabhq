# frozen_string_literal: true

module Projects
  module Ml
    class CandidateFinder
      VALID_ORDER_BY_TYPES = %w[column metric].freeze
      VALID_ORDER_BY_COLUMNS = %w[name created_at id].freeze
      VALID_SORT = %w[asc desc].freeze

      def initialize(experiment, params = {})
        @experiment = experiment
        @params = params
      end

      def execute
        candidates = @experiment.candidates.including_relationships

        candidates = by_name(candidates)
        order(candidates)
      end

      private

      def by_name(candidates)
        return candidates unless @params[:name].present?

        candidates.by_name(@params[:name])
      end

      def order(candidates)
        return candidates.order_by_metric(metric_order_by, sort) if order_by_metric?

        candidates.order_by("#{column_order_by}_#{sort}").with_order_id_desc
      end

      def order_by_metric?
        order_by_type == 'metric'
      end

      def order_by_type
        valid_or_default(@params[:order_by_type], VALID_ORDER_BY_TYPES, 'column')
      end

      def column_order_by
        valid_or_default(@params[:order_by], VALID_ORDER_BY_COLUMNS, 'created_at')
      end

      def metric_order_by
        @params[:order_by] || ''
      end

      def sort
        valid_or_default(@params[:sort]&.downcase, VALID_SORT, 'desc')
      end

      def valid_or_default(value, valid_values, default)
        return value if valid_values.include?(value)

        default
      end
    end
  end
end
