# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    IllegalRange = Class.new(ArgumentError)

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

    def self.range(lhs, rhs)
      if lhs && rhs
        ClosedRange.new(lhs, rhs)
      elsif lhs
        StartingFrom.new(lhs)
      elsif rhs
        EndingAt.new(rhs)
      else
        raise IllegalRange, 'One of rhs or lhs must be provided' unless lhs && rhs
      end
    end

    class ClosedRange < RelativePositioning::Range
      def initialize(lhs, rhs)
        @lhs, @rhs = lhs, rhs
        raise IllegalRange, 'Either lhs or rhs is missing' unless lhs && rhs
        raise IllegalRange, 'lhs and rhs cannot be the same object' if lhs == rhs
      end
    end

    class StartingFrom < RelativePositioning::Range
      include Gitlab::Utils::StrongMemoize

      def initialize(lhs)
        @lhs = lhs
        raise IllegalRange, 'lhs is required' unless lhs
      end

      def rhs
        strong_memoize(:rhs) { lhs.rhs_neighbour }
      end
    end

    class EndingAt < RelativePositioning::Range
      include Gitlab::Utils::StrongMemoize

      def initialize(rhs)
        @rhs = rhs
        raise IllegalRange, 'rhs is required' unless rhs
      end

      def lhs
        strong_memoize(:lhs) { rhs.lhs_neighbour }
      end
    end
  end
end
