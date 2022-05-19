# frozen_string_literal: true

module Types
  class ColorType < BaseScalar
    graphql_name 'Color'
    description <<~DESC
      Color represented as a hex code or named color.

      For example: "#fefefe".
    DESC

    def self.coerce_input(value, ctx)
      color = Gitlab::Color.of(value)
      raise GraphQL::CoercionError, 'Not a color' unless color.valid?

      color
    rescue ArgumentError => e
      raise GraphQL::CoercionError, e.message
    end

    def self.coerce_result(value, ctx)
      value.to_s
    end
  end
end
