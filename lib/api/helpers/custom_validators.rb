module API
  module Helpers
    module CustomValidators
      class Absence < Grape::Validations::Base
        def validate_param!(attr_name, params)
          return if params.respond_to?(:key?) && !params.key?(attr_name)

          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:absence)
        end
      end
    end
  end
end

Grape::Validations.register_validator(:absence, ::API::Helpers::CustomValidators::Absence)
