# frozen_string_literal: true

module Gitlab
  module RelativePositioning
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
  end
end
