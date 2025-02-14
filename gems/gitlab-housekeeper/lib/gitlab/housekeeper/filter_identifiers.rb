# frozen_string_literal: true

module Gitlab
  module Housekeeper
    class FilterIdentifiers
      def initialize(filters)
        @filters = filters
      end

      def matches_filters?(identifiers)
        @filters.all? do |filter|
          identifiers.any? do |identifier|
            identifier.match?(filter)
          end
        end
      end
    end
  end
end
