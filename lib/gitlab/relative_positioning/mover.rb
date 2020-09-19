# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    class Mover
      attr_reader :range, :start_position

      def initialize(start, range)
        @range = range
        @start_position = start
      end

      def move_to_end(object)
        focus = context(object, ignoring: object)
        max_pos = focus.max_relative_position

        move_to_range_end(focus, max_pos)
      end

      def move_to_start(object)
        focus = context(object, ignoring: object)
        min_pos = focus.min_relative_position

        move_to_range_start(focus, min_pos)
      end

      def move(object, first, last)
        raise ArgumentError, 'object is required' unless object

        lhs = context(first, ignoring: object)
        rhs = context(last, ignoring: object)
        focus = context(object)
        range = RelativePositioning.range(lhs, rhs)

        if range.cover?(focus)
          # Moving a object already within a range is a no-op
        elsif range.open_on_left?
          move_to_range_start(focus, range.rhs.relative_position)
        elsif range.open_on_right?
          move_to_range_end(focus, range.lhs.relative_position)
        else
          pos_left, pos_right = create_space_between(range)
          desired_position = position_between(pos_left, pos_right)
          focus.place_at_position(desired_position, range.lhs)
        end
      end

      def context(object, ignoring: nil)
        return unless object

        ItemContext.new(object, range, ignoring: ignoring)
      end

      private

      def gap_too_small?(pos_a, pos_b)
        return false unless pos_a && pos_b

        (pos_a - pos_b).abs < MIN_GAP
      end

      def move_to_range_end(context, max_pos)
        range_end = range.last + 1

        new_pos = if max_pos.nil?
                    start_position
                  elsif gap_too_small?(max_pos, range_end)
                    max = context.max_sibling
                    max.ignoring = context.object
                    max.shift_left
                    position_between(max.relative_position, range_end)
                  else
                    position_between(max_pos, range_end)
                  end

        context.object.relative_position = new_pos
      end

      def move_to_range_start(context, min_pos)
        range_end = range.first - 1

        new_pos = if min_pos.nil?
                    start_position
                  elsif gap_too_small?(min_pos, range_end)
                    sib = context.min_sibling
                    sib.ignoring = context.object
                    sib.shift_right
                    position_between(sib.relative_position, range_end)
                  else
                    position_between(min_pos, range_end)
                  end

        context.object.relative_position = new_pos
      end

      def create_space_between(range)
        pos_left = range.lhs&.relative_position
        pos_right = range.rhs&.relative_position

        return [pos_left, pos_right] unless gap_too_small?(pos_left, pos_right)

        gap = range.rhs.create_space_left
        [pos_left - gap.delta, pos_right]
      rescue NoSpaceLeft
        gap = range.lhs.create_space_right
        [pos_left, pos_right + gap.delta]
      end

      # This method takes two integer values (positions) and
      # calculates the position between them. The range is huge as
      # the maximum integer value is 2147483647.
      #
      # We avoid open ranges by clamping the range to [MIN_POSITION, MAX_POSITION].
      #
      # Then we handle one of three cases:
      #  - If the gap is too small, we raise NoSpaceLeft
      #  - If the gap is larger than MAX_GAP, we place the new position at most
      #    IDEAL_DISTANCE from the edge of the gap.
      #  - otherwise we place the new position at the midpoint.
      #
      # The new position will always satisfy: pos_before <= midpoint <= pos_after
      #
      # As a precondition, the gap between pos_before and pos_after MUST be >= 2.
      # If the gap is too small, NoSpaceLeft is raised.
      #
      # @raises NoSpaceLeft
      def position_between(pos_before, pos_after)
        pos_before ||= range.first
        pos_after ||= range.last

        pos_before, pos_after = [pos_before, pos_after].sort

        gap_width = pos_after - pos_before

        if gap_too_small?(pos_before, pos_after)
          raise NoSpaceLeft
        elsif gap_width > MAX_GAP
          if pos_before <= range.first
            pos_after - IDEAL_DISTANCE
          elsif pos_after >= range.last
            pos_before + IDEAL_DISTANCE
          else
            midpoint(pos_before, pos_after)
          end
        else
          midpoint(pos_before, pos_after)
        end
      end

      def midpoint(lower_bound, upper_bound)
        ((lower_bound + upper_bound) / 2.0).ceil.clamp(lower_bound, upper_bound - 1)
      end
    end
  end
end
