# frozen_string_literal: true

module API
  module Validations
    module Validators
      class IntegerOrCustomValue < Grape::Validations::Validators::Base
        def initialize(attrs, options, required, scope, **opts)
          @custom_values = extract_custom_values(options)
          super
        end

        def validate_param!(attr_name, params)
          value = params[attr_name]

          return if value.is_a?(Integer)
          return if @custom_values.map(&:downcase).include?(value.to_s.downcase)

          valid_options = Gitlab::Sentence.to_exclusive_sentence(['an integer'] + @custom_values)
          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "should be #{valid_options}, however got #{value}"
          )
        end

        private

        def extract_custom_values(options)
          options.is_a?(Hash) ? options[:values] : options
        end
      end
    end
  end
end
