# frozen_string_literal: true

module API
  module Validations
    module Validators
      class Absence < Grape::Validations::Validators::Base
        def validate_param!(attr_name, params)
          return if params.respond_to?(:key?) && !params.key?(attr_name)

          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: message(:absence))
        end
      end
    end
  end
end
