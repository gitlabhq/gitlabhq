# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    class Range
      attr_reader :lhs, :rhs

      def open_on_left?
        lhs.nil?
      end

      def open_on_right?
        rhs.nil?
      end

      def cover?(item_context)
        return false unless item_context
        return false unless item_context.positioned?
        return true if item_context.object == lhs&.object
        return true if item_context.object == rhs&.object

        pos = item_context.relative_position

        return lhs.relative_position < pos if open_on_right?
        return pos < rhs.relative_position if open_on_left?

        lhs.relative_position < pos && pos < rhs.relative_position
      end

      def ==(other)
        other.is_a?(RelativePositioning::Range) && lhs == other.lhs && rhs == other.rhs
      end
    end
  end
end
