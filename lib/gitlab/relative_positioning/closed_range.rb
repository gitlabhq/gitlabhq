# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    class ClosedRange < RelativePositioning::Range
      def initialize(lhs, rhs)
        @lhs = lhs
        @rhs = rhs
        raise IllegalRange, 'Either lhs or rhs is missing' unless lhs && rhs
        raise IllegalRange, 'lhs and rhs cannot be the same object' if lhs == rhs
      end
    end
  end
end
