# frozen_string_literal: true

module TestValidations
  module Types
    class CommaSeparatedToIntegerArray
      def self.coerce
        ->(value) { value.to_s.split(',').map { |v| v.strip.to_i } }
      end
    end
  end
end
