# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class AggregationResult
        include Enumerable

        def initialize(engine, plan, query)
          @engine = engine
          @plan = plan
          @query = query
        end

        # TODO: add interface for paginating

        delegate :to_a, :[], :each, to: :loaded_results

        private

        attr_reader :engine, :plan, :query

        def loaded_results
          @loaded_results ||= format_data(load_data)
        end

        def load_data
          raise NoMethodError
        end

        def format_data(raw_data)
          Formatter.new(engine, plan).format_data(raw_data)
        end
      end
    end
  end
end
