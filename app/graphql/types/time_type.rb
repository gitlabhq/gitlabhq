# frozen_string_literal: true

module Types
  class TimeType < BaseScalar
    graphql_name 'Time'
    description <<~DESC
      Time represented in ISO 8601.

      For example: "2021-03-09T14:58:50+00:00".

      See `https://www.iso.org/iso-8601-date-and-time-format.html`.
    DESC

    def self.coerce_input(value, ctx)
      # arguments can be nil, so don't raise an error
      return if value.nil?

      Time.parse(value)
    rescue ArgumentError, TypeError => e
      raise GraphQL::CoercionError, e.message
    end

    def self.coerce_result(value, ctx)
      value.iso8601
    end
  end
end
