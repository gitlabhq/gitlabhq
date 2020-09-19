# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    STEPS = 10
    IDEAL_DISTANCE = 2**(STEPS - 1) + 1

    MIN_POSITION = Gitlab::Database::MIN_INT_VALUE
    START_POSITION = 0
    MAX_POSITION = Gitlab::Database::MAX_INT_VALUE

    MAX_GAP = IDEAL_DISTANCE * 2
    MIN_GAP = 2

    NoSpaceLeft = Class.new(StandardError)
  end
end
