# frozen_string_literal: true

# This class represents the value of a CI input. It is used to provide default values to UI forms that users can
# use to populate inputs for a pipeline, and to configure inputs values for pipeline schedules.

module Types
  module Ci
    module Inputs
      class ValueType < BaseScalar
        graphql_name 'CiInputsValue'
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
