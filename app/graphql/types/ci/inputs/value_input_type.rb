# frozen_string_literal: true

module Types
  module Ci
    module Inputs
      class ValueInputType < BaseScalar
        graphql_name 'CiInputsValueInputType'
        description 'Value for a CI input. Can be a string, array, number, or boolean.'

        def self.coerce_input(value, _ctx)
          case value
          when String, Array, Numeric, TrueClass, FalseClass, NilClass
            value
          else
            raise GraphQL::CoercionError, 'Invalid CI input value'
          end
        end
      end
    end
  end
end
