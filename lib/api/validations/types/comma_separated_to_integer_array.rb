# frozen_string_literal: true

module API
  module Validations
    module Types
      class CommaSeparatedToIntegerArray < CommaSeparatedToArray
        def self.coerce
          ->(value) do
            super.call(value).map(&:to_i)
          end
        end
      end
    end
  end
end
