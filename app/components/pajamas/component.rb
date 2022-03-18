# frozen_string_literal: true

module Pajamas
  class Component < ViewComponent::Base
    private

    # :nocov:

    # Filter a given a value against a list of allowed values
    # If no value is given or value is not allowed return default one
    #
    # @param [Object] value
    # @param [Enumerable] allowed_values
    # @param [Object] default
    def filter_attribute(value, allowed_values, default: nil)
      return default unless value
      return value if allowed_values.include?(value)

      default
    end
    # :nocov:
  end
end
