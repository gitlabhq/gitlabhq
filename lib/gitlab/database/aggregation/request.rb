# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Request
        attr_reader :filters, :dimensions, :metrics, :order

        def initialize(metrics:, filters: [], dimensions: [], order: [])
          @filters = filters || []
          @dimensions = dimensions || []
          @metrics = metrics
          @order = order || []
        end

        def to_query_plan(engine)
          QueryPlan.new(engine, self)
        end
      end
    end
  end
end
