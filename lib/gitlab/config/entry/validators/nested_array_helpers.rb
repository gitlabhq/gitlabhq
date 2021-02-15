# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      module Validators
        # Include this module to validate deeply nested array of values
        #
        # class MyNestedValidator < ActiveModel::EachValidator
        #   include NestedArrayHelpers
        #
        #   def validate_each(record, attribute, value)
        #     max_depth = options.fetch(:max_depth, 1)
        #
        #     unless validate_nested_array(value, max_depth) { |v| v.is_a?(Integer) }
        #       record.errors.add(attribute, "is invalid")
        #     end
        #   end
        # end
        #
        module NestedArrayHelpers
          def validate_nested_array(value, max_depth = 1, &validator_proc)
            return false unless value.is_a?(Array)

            validate_nested_array_recursively(value, max_depth, &validator_proc)
          end

          private

          # rubocop: disable Performance/RedundantBlockCall
          # Disables Rubocop rule for easier readability reasons.
          def validate_nested_array_recursively(value, nesting_level, &validator_proc)
            return true if validator_proc.call(value)
            return false if nesting_level <= 0
            return false unless value.is_a?(Array)

            value.all? do |element|
              validate_nested_array_recursively(element, nesting_level - 1, &validator_proc)
            end
          end
          # rubocop: enable Performance/RedundantBlockCall
        end
      end
    end
  end
end
