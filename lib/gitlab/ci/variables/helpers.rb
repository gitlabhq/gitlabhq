# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      module Helpers
        class << self
          def merge_variables(current_vars, new_vars)
            current_vars = transform_from_yaml_variables(current_vars)
            new_vars = transform_from_yaml_variables(new_vars)

            transform_to_yaml_variables(
              current_vars.merge(new_vars)
            )
          end

          def transform_to_yaml_variables(vars)
            vars.to_h.map do |key, value|
              { key: key.to_s, value: value, public: true }
            end
          end

          def transform_from_yaml_variables(vars)
            return vars.stringify_keys if vars.is_a?(Hash)

            vars.to_a.to_h { |var| [var[:key].to_s, var[:value]] }
          end

          def inherit_yaml_variables(from:, to:, inheritance:)
            merge_variables(apply_inheritance(from, inheritance), to)
          end

          private

          def apply_inheritance(variables, inheritance)
            case inheritance
            when true then variables
            when false then {}
            when Array then variables.select { |var| inheritance.include?(var[:key]) }
            end
          end
        end
      end
    end
  end
end
