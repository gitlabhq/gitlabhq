# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Handles variable expansion
          class VariablesExpander < Base
            def expand(data)
              if data.is_a?(String)
                expand_variable(data)
              else
                transform_and_expand_variable(data)
              end
            end

            private

            def process_without_instrumentation(locations)
              locations.map { |location| expand(location) }
            end

            def transform_and_expand_variable(data)
              data.transform_values do |values|
                case values
                when Array
                  values.map { |value| expand_variable(value.to_s) }
                when String
                  expand_variable(values)
                else
                  values
                end
              end
            end

            def expand_variable(data)
              ExpandVariables.expand(data, -> { variables })
            end

            def variables
              @variables ||= context.variables_hash
            end
          end
        end
      end
    end
  end
end
