# frozen_string_literal: true

module TestValidations
  module Types
    class CommaSeparatedToArray
      def self.coerce
        ->(value) { value.to_s.split(',').map(&:strip) }
      end
    end
  end
end
