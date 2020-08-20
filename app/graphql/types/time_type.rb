# frozen_string_literal: true

module Types
  class TimeType < BaseScalar
    graphql_name 'Time'
    description 'Time represented in ISO 8601'

    def self.coerce_input(value, ctx)
      Time.parse(value)
    rescue ArgumentError, TypeError => e
      raise GraphQL::CoercionError, e.message
    end

    def self.coerce_result(value, ctx)
      value.iso8601
    end
  end
end
