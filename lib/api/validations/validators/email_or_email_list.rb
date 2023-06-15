# frozen_string_literal: true

module API
  module Validations
    module Validators
      class EmailOrEmailList < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          return unless value

          case value
          when String
            return if value.split(',').map { |v| ValidateEmail.valid?(v) }.all?
          when Array
            return if value.map { |v| ValidateEmail.valid?(v) }.all?
          end

          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "contains an invalid email address"
          )
        end
      end
    end
  end
end
