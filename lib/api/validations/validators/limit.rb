# frozen_string_literal: true

module API
  module Validations
    module Validators
      class Limit < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]

          return if value.nil? || value.size <= @option

          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "#{@scope.full_name(attr_name)} must be less than #{@option} characters"
          )
        end
      end
    end
  end
end
