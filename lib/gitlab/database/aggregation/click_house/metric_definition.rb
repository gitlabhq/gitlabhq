# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class MetricDefinition < PartDefinition
          include ParameterizedDefinition

          def initialize(*args, **kwargs)
            super
            @secondary_expression = kwargs[:if]
          end

          def to_inner_arel(context)
            expression ? expression.call(expression_params(context)) : context[:scope][name]
          end

          def secondary_arel(context)
            secondary_expression&.call(expression_params(context))
          end

          def to_outer_arel(context)
            Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]
          end

          def requires_window?
            false
          end

          private

          def expression_params(context)
            return {} unless parameterized?

            configuration = context[name]
            parameters.keys.each_with_object({}) do |key, h|
              val = instance_parameter(key, configuration)
              h[key] = val if val
            end
          end
        end
      end
    end
  end
end
