# frozen_string_literal: true

module Types
  class DateType < BaseScalar
    graphql_name 'Date'
    description 'Date represented in ISO 8601'

    def self.coerce_input(value, ctx)
      return if value.nil?

      Date.iso8601(value)
    rescue ArgumentError, TypeError => e
      raise GraphQL::CoercionError, e.message
    end

    def self.coerce_result(value, ctx)
      return if value.nil?

      value.to_date.iso8601
    end
  end
end
