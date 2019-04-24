# frozen_string_literal: true

module API
  module Validations
    class CheckAssigneesCount < Grape::Validations::Base
      def self.coerce
        lambda do |value|
          case value
          when String
            [value]
          when Array
            value
          when CheckAssigneesCount
            value
          else
            []
          end
        end
      end

      def validate_param!(attr_name, params)
        unless param_allowed?(attr_name, params)
          raise Grape::Exceptions::Validation,
                params: [@scope.full_name(attr_name)],
                message: "allows one value, but found #{params[attr_name].size}: #{params[attr_name].join(", ")}"
        end
      end

      private

      def param_allowed?(attr_name, params)
        params[attr_name].size <= 1
      end
    end
  end
end
