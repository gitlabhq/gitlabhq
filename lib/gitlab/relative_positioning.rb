# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    STEPS = 10
    IDEAL_DISTANCE = (2**(STEPS - 1)) + 1

    MIN_POSITION = Gitlab::Database::MIN_INT_VALUE
    START_POSITION = 0
    MAX_POSITION = Gitlab::Database::MAX_INT_VALUE

    MAX_GAP = IDEAL_DISTANCE * 2
    MIN_GAP = 2

    NoSpaceLeft = Class.new(StandardError)
    InvalidPosition = Class.new(StandardError)
    IllegalRange = Class.new(ArgumentError)
    IssuePositioningDisabled = Class.new(StandardError)

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
  end
end
