# frozen_string_literal: true

module API
  module Validations
    module Validators
      # Grape skips an optional array's nested `requires` block when every element is blank
      # (`ParamsScope#should_validate?`), and a required array still admits an empty nested array.
      class NoBlankElements < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          return unless value.is_a?(Array)

          qualified_name = @scope.full_name(attr_name)
          blank_element_names = value.each_with_index.filter_map do |element, index|
            "#{qualified_name}[#{index}]" if element.blank?
          end

          return if blank_element_names.empty?

          raise Grape::Exceptions::Validation.new(params: blank_element_names, message: 'is blank')
        end
      end
    end
  end
end
