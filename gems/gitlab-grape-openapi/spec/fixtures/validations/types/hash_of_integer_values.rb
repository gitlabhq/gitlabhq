# frozen_string_literal: true

module TestValidations
  module Types
    class HashOfIntegerValues
      def self.coerce
        ->(value) { value.transform_values(&:to_i) }
      end
    end
  end
end
