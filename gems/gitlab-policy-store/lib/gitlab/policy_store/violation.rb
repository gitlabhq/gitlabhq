# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class Violation
      attr_reader :id, :details

      def initialize(id:, details: nil)
        @id = id
        @details = deep_freeze(details)

        freeze
      end

      def to_h
        {
          id: id,
          details: details
        }
      end

      def ==(other)
        other.is_a?(self.class) && other.to_h == to_h
      end
      alias_method :eql?, :==

      def hash
        to_h.hash
      end

      private

      # freeze on the object is shallow; without this a caller could still
      # mutate the details hash in place.
      def deep_freeze(value)
        case value
        when Hash
          value.each do |key, nested|
            key.freeze
            deep_freeze(nested)
          end
        when Array
          value.each { |item| deep_freeze(item) }
        end

        value.freeze
      end
    end
  end
end
