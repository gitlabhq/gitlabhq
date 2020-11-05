# frozen_string_literal: true

module API
  module Validations
    module Validators
      class EmailOrEmailList < Grape::Validations::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          return unless value

          return if value.split(',').map { |v| ValidateEmail.valid?(v) }.all?

          raise Grape::Exceptions::Validation,
            params: [@scope.full_name(attr_name)],
            message: "contains an invalid email address"
        end
      end
    end
  end
end
