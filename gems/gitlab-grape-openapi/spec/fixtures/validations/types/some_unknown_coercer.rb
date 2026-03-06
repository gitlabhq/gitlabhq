# frozen_string_literal: true

module TestValidations
  module Types
    class SomeUnknownCoercer
      def self.coerce
        ->(value) { value }
      end
    end
  end
end
