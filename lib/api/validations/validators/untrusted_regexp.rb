# frozen_string_literal: true

module API
  module Validations
    module Validators
      class UntrustedRegexp < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          value = params[attr_name]
          return unless value

          Gitlab::UntrustedRegexp.new(value)
        rescue RegexpError => e
          message = "is an invalid regexp: #{e.message}"
          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: message)
        end
      end
    end
  end
end
