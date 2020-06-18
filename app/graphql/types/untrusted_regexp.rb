# frozen_string_literal: true

module Types
  class UntrustedRegexp < Types::BaseScalar
    description 'A regexp containing patterns sourced from user input'

    def self.coerce_input(input_value, _)
      return unless input_value

      Gitlab::UntrustedRegexp.new(input_value)

      input_value
    rescue RegexpError => e
      message = "#{input_value} is an invalid regexp: #{e.message}"
      raise GraphQL::CoercionError, message
    end

    def self.coerce_result(ruby_value, _)
      ruby_value.to_s
    end
  end
end
