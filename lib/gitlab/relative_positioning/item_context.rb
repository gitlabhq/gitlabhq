# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    # This class is API private - it should not be explicitly instantiated
    # outside of tests
    # rubocop: disable CodeReuse/ActiveRecord
    class ItemContext
      include Gitlab::Utils::StrongMemoize

      attr_reader :object, :model_class, :range
      attr_accessor :ignoring

      def initialize(object, range, ignoring: nil)
        @object = object
        @range = range
        @model_class = object.class
        @ignoring = ignoring
      end

      def ==(other)
        other.is_a?(self.class) && other.object == object && other.range == range && other.ignoring == ignoring
      end

      def positioned?
        relative_position.present?
      end

      def min_relative_position
        strong_memoize(:min_relative_position) { calculate_relative_position('MIN') }
      end

      def max_relative_position
        strong_memoize(:max_relative_position) { calculate_relative_position('MAX') }
      end

      def prev_relative_position
        calculate_relative_position('MAX') { |r| nextify(r, false) } if object.relative_position
      end

      def next_relative_position
        calculate_relative_position('MIN') { |r| nextify(r) } if object.relative_position
      end

      def nextify(relation, gt = true)
        if gt
          relation.where("relative_position > ?", relative_position)
        else
          relation.where("relative_position < ?", relative_position)
        end
      end

      def relative_siblings(relation = scoped_items)
        object.exclude_self(relation)
      end

      # Handles the possibility that the position is already occupied by a sibling
      def place_at_position(position, lhs)
        current_occupant = relative_siblings.find_by(relative_position: position)

        if current_occupant.present?
          Mover.new(position, range).move(object, lhs.object, current_occupant)
        else
          object.relative_position = position
        end
      end

      def lhs_neighbour
        scoped_items
          .where('relative_position < ?', relative_position)
          .reorder(relative_position: :desc)
          .first
          .then { |x| neighbour(x) }
      end

      def rhs_neighbour
        scoped_items
          .where('relative_position > ?', relative_position)
          .reorder(relative_position: :asc)
          .first
          .then { |x| neighbour(x) }
      end

      def neighbour(item)
        return unless item.present?

        self.class.new(item, range, ignoring: ignoring)
      end

      def scoped_items
        r = model_class.relative_positioning_query_base(object)
        r = object.exclude_self(r, excluded: ignoring) if ignoring.present?
        r
      end

      def calculate_relative_position(calculation)
        # When calculating across projects, this is much more efficient than
        # MAX(relative_position) without the GROUP BY, due to index usage:
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/54276#note_119340977
        relation = scoped_items
                     .order(Gitlab::Database.nulls_last_order('position', 'DESC'))
                     .group(grouping_column)
                     .limit(1)

        relation = yield relation if block_given?

        relation
          .pluck(grouping_column, Arel.sql("#{calculation}(relative_position) AS position"))
          .first&.last
      end

      def grouping_column
        model_class.relative_positioning_parent_column
      end

      def max_sibling
        sib = relative_siblings
          .order(Gitlab::Database.nulls_last_order('relative_position', 'DESC'))
          .first

        neighbour(sib)
      end

      def min_sibling
        sib = relative_siblings
          .order(Gitlab::Database.nulls_last_order('relative_position', 'ASC'))
          .first

        neighbour(sib)
      end

      def at_position(position)
        item = scoped_items.find_by(relative_position: position)

        raise InvalidPosition, 'No item found at the specified position' if item.nil?

        neighbour(item)
      end

      def shift_left
        move_sequence_before(true)
        object.reset_relative_position
      end

      def shift_right
        move_sequence_after(true)
        object.reset_relative_position
      end

      def create_space_left
        find_next_gap_before.tap { |gap| move_sequence_before(false, next_gap: gap) }
      end

      def create_space_right
        find_next_gap_after.tap { |gap| move_sequence_after(false, next_gap: gap) }
      end

      def find_next_gap_before
        items_with_next_pos = scoped_items
                                .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position DESC) AS next_pos')
                                .where('relative_position <= ?', relative_position)
                                .order(relative_position: :desc)

        find_next_gap(items_with_next_pos, range.first)
      end

      def find_next_gap_after
        items_with_next_pos = scoped_items
                                .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position ASC) AS next_pos')
                                .where('relative_position >= ?', relative_position)
                                .order(:relative_position)

        find_next_gap(items_with_next_pos, range.last)
      end

      def find_next_gap(items_with_next_pos, default_end)
        gap = model_class
          .from(items_with_next_pos, :items)
          .where('next_pos IS NULL OR ABS(pos::bigint - next_pos::bigint) >= ?', MIN_GAP)
          .limit(1)
          .pluck(:pos, :next_pos)
          .first

        return if gap.nil? || gap.first == default_end

        Gap.new(gap.first, gap.second || default_end)
      end

      def relative_position
        object.relative_position
      end

      private

      # Moves the sequence before the current item to the middle of the next gap
      # For example, we have
      #
      #   5 . . . . . 11 12 13 14 [15] 16 . 17
      #               -----------
      #
      # This moves the sequence [11 12 13 14] to [8 9 10 11], so we have:
      #
      #   5 . . 8 9 10 11 . . . [15] 16 . 17
      #         ---------
      #
      # Creating a gap to the left of the current item. We can understand this as
      # dividing the 5 spaces between 5 and 11 into two smaller gaps of 2 and 3.
      #
      # If `include_self` is true, the current item will also be moved, creating a
      # gap to the right of the current item:
      #
      #   5 . . 8 9 10 11 [14] . . . 16 . 17
      #         --------------
      #
      # As an optimization, the gap can be precalculated and passed to this method.
      #
      # @api private
      # @raises NoSpaceLeft if the sequence cannot be moved
      def move_sequence_before(include_self = false, next_gap: find_next_gap_before)
        raise NoSpaceLeft unless next_gap.present?

        delta = next_gap.delta

        move_sequence(next_gap.start_pos, relative_position, -delta, include_self)
      end

      # Moves the sequence after the current item to the middle of the next gap
      # For example, we have:
      #
      #   8 . 10 [11] 12 13 14 15 . . . . . 21
      #               -----------
      #
      # This moves the sequence [12 13 14 15] to [15 16 17 18], so we have:
      #
      #   8 . 10 [11] . . . 15 16 17 18 . . 21
      #                     -----------
      #
      # Creating a gap to the right of the current item. We can understand this as
      # dividing the 5 spaces between 15 and 21 into two smaller gaps of 3 and 2.
      #
      # If `include_self` is true, the current item will also be moved, creating a
      # gap to the left of the current item:
      #
      #   8 . 10 . . . [14] 15 16 17 18 . . 21
      #                ----------------
      #
      # As an optimization, the gap can be precalculated and passed to this method.
      #
      # @api private
      # @raises NoSpaceLeft if the sequence cannot be moved
      def move_sequence_after(include_self = false, next_gap: find_next_gap_after)
        raise NoSpaceLeft unless next_gap.present?

        delta = next_gap.delta

        move_sequence(relative_position, next_gap.start_pos, delta, include_self)
      end

      def move_sequence(start_pos, end_pos, delta, include_self = false)
        relation = include_self ? scoped_items : relative_siblings

        object.update_relative_siblings(relation, (start_pos..end_pos), delta)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
