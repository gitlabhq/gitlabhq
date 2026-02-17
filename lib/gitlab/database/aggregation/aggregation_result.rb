# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class AggregationResult
        include Enumerable

        def initialize(engine, plan, query, **options)
          @engine = engine
          @plan = plan
          @query = query
          @options = options
        end

        def limit(limit_value)
          self.class.new(
            engine,
            plan,
            query.limit(limit_value),
            **options
          )
        end

        def offset(offset_value)
          self.class.new(
            engine,
            plan,
            query.offset(offset_value),
            **options
          )
        end

        delegate :to_a, :[], :each, to: :loaded_results

        private

        attr_reader :engine, :plan, :query, :options

        def loaded_results
          @loaded_results ||= format_data(transform_keys(load_data))
        end

        def load_data
          raise NoMethodError
        end

        def format_data(raw_data)
          Formatter.new(engine, plan).format_data(raw_data)
        end

        def transform_keys(raw_data)
          return raw_data unless options[:column_prefix]

          raw_data.map do |row|
            row.transform_keys do |key|
              key.sub(options[:column_prefix], '')
            end
          end
        end
      end
    end
  end
end
