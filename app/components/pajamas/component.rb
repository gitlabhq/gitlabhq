# frozen_string_literal: true

module Pajamas
  class Component < ViewComponent::Base
    private

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

    # Add CSS classes and additional options to an existing options hash
    #
    # @param [Hash] options
    # @param [Array] css_classes
    # @param [Hash] additional_option
    def format_options(options:, css_classes: [], additional_options: {})
      options.merge({ class: [*css_classes, options[:class]].flatten.compact }, additional_options)
    end
  end
end
