# frozen_string_literal: true

module API
  module Validations
    module Validators
      class CheckAssigneesCount < Grape::Validations::Base
        def self.coerce
          lambda do |value|
            case value
            when String, Array
              Array.wrap(value)
            else
              []
            end
          end
        end

        def validate_param!(attr_name, params)
          return if param_allowed?(attr_name, params)

          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: "allows one value, but found #{params[attr_name].size}: #{params[attr_name].join(", ")}"
          )
        end

        private

        def param_allowed?(attr_name, params)
          params[attr_name].size <= 1
        end
      end
    end
  end
end

API::Validations::Validators::CheckAssigneesCount.prepend_mod_with('API::Validations::Validators::CheckAssigneesCount')
