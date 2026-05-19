# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        class Filter < BasePart
          def initialize(definition, configuration, query_plan:)
            super(definition, format_configuration(definition, configuration), query_plan: query_plan)
          end

          private

          def format_configuration(definition, configuration)
            return configuration unless definition&.formatter

            configuration.merge(values: definition.formatter.call(configuration[:values]))
          end
        end
      end
    end
  end
end
