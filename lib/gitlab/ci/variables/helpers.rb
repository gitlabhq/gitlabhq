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

            vars.to_a.map { |var| [var[:key].to_s, var[:value]] }.to_h
          end
        end
      end
    end
  end
end
