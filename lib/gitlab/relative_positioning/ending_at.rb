# frozen_string_literal: true

module Gitlab
  module RelativePositioning
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
