# frozen_string_literal: true

module API
  module Validations
    module Types
      class CommaSeparatedToIntegerArray < CommaSeparatedToArray
        def self.coerce
          lambda do |value|
            super.call(value).map(&:to_i)
          end
        end
      end
    end
  end
end
