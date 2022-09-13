# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      module Helpers
        class << self
          def merge_variables(current_vars, new_vars)
            return current_vars if new_vars.blank?

            current_vars = transform_to_array(current_vars) if current_vars.is_a?(Hash)
            new_vars = transform_to_array(new_vars) if new_vars.is_a?(Hash)

            (new_vars + current_vars).uniq { |var| var[:key] }
          end

          def transform_to_array(vars)
            return [] if vars.blank?

            vars.map do |key, data|
              if data.is_a?(Hash)
                { key: key.to_s, **data.except(:key) }
              else
                { key: key.to_s, value: data }
              end
            end
          end

          def inherit_yaml_variables(from:, to:, inheritance:)
            merge_variables(apply_inheritance(from, inheritance), to)
          end

          private

          def apply_inheritance(variables, inheritance)
            case inheritance
            when true then variables
            when false then []
            when Array then variables.select { |var| inheritance.include?(var[:key]) }
            end
          end
        end
      end
    end
  end
end
