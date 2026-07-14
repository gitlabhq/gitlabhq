# frozen_string_literal: true

module Gitlab
  module Graphql
    module VariableFilters
      # Redacts the `value` field inside `inputs` arrays in GraphQL mutation
      # variables, preserving `name` for debuggability. CI inputs may contain
      # user-supplied secrets that must not appear in logs.
      module CiInputsFilter
        FILTERED = '[FILTERED]'

        def self.filter(variables)
          return variables unless variables.is_a?(Hash)

          variables.each_with_object({}) do |(key, val), result|
            result[key] =
              if key.to_s == 'inputs' && val.is_a?(Array)
                val.map { |item| item.is_a?(Hash) && item.key?('value') ? item.merge('value' => FILTERED) : item }
              elsif val.is_a?(Hash)
                filter(val)
              else
                val
              end
          end
        end
      end
    end
  end
end
