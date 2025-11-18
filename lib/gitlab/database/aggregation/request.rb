# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Request
        attr_reader :metrics, :dimensions, :order

        def initialize(metrics:, dimensions:, order: [])
          @metrics = metrics
          @dimensions = dimensions
          @order = order
        end
      end
    end
  end
end
