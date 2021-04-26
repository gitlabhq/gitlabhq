# frozen_string_literal: true

module Types
  class DurationType < BaseScalar
    graphql_name 'Duration'
    description <<~DESC
      Duration between two instants, represented as a fractional number of seconds.

      For example: 12.3334
    DESC

    def self.coerce_input(value, ctx)
      case value
      when Float
        value
      when Integer
        value.to_f
      when NilClass
        raise GraphQL::CoercionError, 'Cannot be nil'
      else
        raise GraphQL::CoercionError, "Expected number: got #{value.class}"
      end
    end

    def self.coerce_result(value, ctx)
      value.to_f
    end
  end
end
