# frozen_string_literal: true

module API
  module Validations
    module Validators
      # Grape's `type: Array` does not check element types, and a nested block of optional
      # params skips any element that cannot be looked up by key (the `val.try(:key?, attr_name)`
      # guard in `Validators::Base#validate!`), so a String or Array element reaches the
      # endpoint unvalidated.
      class ObjectElements < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          return unless value.is_a?(Array)

          qualified_name = @scope.full_name(attr_name)
          invalid_element_names = value.each_with_index.filter_map do |element, index|
            "#{qualified_name}[#{index}]" unless element.respond_to?(:key?)
          end

          return if invalid_element_names.empty?

          raise Grape::Exceptions::Validation.new(params: invalid_element_names, message: 'is not an object')
        end
      end
    end
  end
end
