# frozen_string_literal: true
#
module Gitlab
  module RelativePositioning
    class Gap
      attr_reader :start_pos, :end_pos

      def initialize(start_pos, end_pos)
        @start_pos = start_pos
        @end_pos = end_pos
      end

      def ==(other)
        other.is_a?(self.class) && other.start_pos == start_pos && other.end_pos == end_pos
      end

      def delta
        ((start_pos - end_pos) / 2.0).abs.ceil.clamp(0, RelativePositioning::IDEAL_DISTANCE)
      end
    end
  end
end
