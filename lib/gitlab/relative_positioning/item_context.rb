# frozen_string_literal: true

module Gitlab
  module RelativePositioning
    # This class is API private - it should not be explicitly instantiated
    # outside of tests
    # rubocop: disable CodeReuse/ActiveRecord
    class ItemContext
      include Gitlab::Utils::StrongMemoize

      attr_reader :object, :model_class, :range, :ideal_distance, :max_gap
      attr_accessor :ignoring

      def initialize(
        object, range, ignoring: nil,
        ideal_distance: RelativePositioning::IDEAL_DISTANCE,
        max_gap: RelativePositioning::MAX_GAP)
        @object = object
        @range = range
        @model_class = object.class
        @ignoring = ignoring
        @ideal_distance = ideal_distance
        @max_gap = max_gap
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
          relation.where(position_column.gt(relative_position))
        else
          relation.where(position_column.lt(relative_position))
        end
      end

      # The Arel column that holds the ordering position. Resolved once per
      # ItemContext from the object's flag state: for issues this is
      # `work_item_positions.relative_position` (root-scoped and joined via
      # `relative_positioning_query_base`) when the cutover flag is on, else
      # `issues.relative_position`; for other models it stays the model's own
      # `relative_position`.
      def position_column
        strong_memoize(:position_column) do
          model_class.relative_positioning_column(object)
        end
      end

      def relative_siblings(relation = scoped_items)
        object.exclude_self(relation)
      end

      # Handles the possibility that the position is already occupied by a sibling
      def place_at_position(position, lhs)
        # rubocop:disable Rails/FindBy -- find_by(relative_position:) would qualify to the model's own table; must match position_column (may be the joined work_item_positions column)
        current_occupant = relative_siblings.where(position_column.eq(position)).take
        # rubocop:enable Rails/FindBy

        if current_occupant.present?
          Mover.new(position, range, ideal_distance: ideal_distance, max_gap: max_gap).move(object, lhs.object, current_occupant)
        else
          object.relative_position = position
        end
      end

      def lhs_neighbour
        neighbour(object.next_object_by_relative_position(ignoring: ignoring, order: :desc))
      end

      def rhs_neighbour
        neighbour(object.next_object_by_relative_position(ignoring: ignoring, order: :asc))
      end

      def neighbour(item)
        return unless item.present?

        self.class.new(item, range, ignoring: ignoring, ideal_distance: ideal_distance, max_gap: max_gap)
      end

      def calculate_relative_position(calculation)
        order = if calculation == 'MIN'
                  Arel.sql('position').asc.nulls_last
                else
                  Arel.sql('position').desc.nulls_last
                end

        # When calculating across projects, this is much more efficient than
        # MAX(relative_position) without the GROUP BY, due to index usage:
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/54276#note_119340977
        relation = scoped_items
                     .order(order)
                     .group(grouping_column)
                     .limit(1)

        relation = yield relation if block_given?

        aggregate = calculation == 'MIN' ? position_column.minimum : position_column.maximum

        relation
          .pick(grouping_column, aggregate.as('position'))&.last
      end

      def grouping_column
        model_class.relative_positioning_parent_column
      end

      def max_sibling
        sib = relative_siblings
          .order(position_column.desc.nulls_last)
          .first

        neighbour(sib)
      end

      def min_sibling
        sib = relative_siblings
          .order(position_column.asc.nulls_last)
          .first

        neighbour(sib)
      end

      def at_position(position)
        # rubocop:disable Rails/FindBy -- find_by(relative_position:) would qualify to the model's own table; must match position_column (may be the joined work_item_positions column)
        item = scoped_items.where(position_column.eq(position)).take
        # rubocop:enable Rails/FindBy

        raise InvalidPosition, 'No item found at the specified position' if item.nil?

        neighbour(item)
      end

      def shift_left(min_gap: MIN_GAP, exclude: nil)
        find_next_gap_before(min_gap: min_gap).tap do |gap|
          move_sequence_before(next_gap: gap, exclude: exclude)
          object.reset_relative_position
        end
      end

      def shift_right(min_gap: MIN_GAP, exclude: nil)
        find_next_gap_after(min_gap: min_gap).tap do |gap|
          move_sequence_after(next_gap: gap, exclude: exclude)
          object.reset_relative_position
        end
      end

      def find_next_gap_before(min_gap: MIN_GAP)
        window = Arel::Nodes::Window.new.order(position_column.desc)
        lead = Arel::Nodes::NamedFunction.new('LEAD', [position_column]).over(window)

        items_with_next_pos = scoped_items
                                .select(position_column.as('pos'), lead.as('next_pos'))
                                .where(position_column.lteq(relative_position))
                                .order(position_column.desc)

        find_next_gap(items_with_next_pos, range.first, order: :desc, min_gap: min_gap)
      end

      def find_next_gap_after(min_gap: MIN_GAP)
        window = Arel::Nodes::Window.new.order(position_column.asc)
        lead = Arel::Nodes::NamedFunction.new('LEAD', [position_column]).over(window)

        items_with_next_pos = scoped_items
                                .select(position_column.as('pos'), lead.as('next_pos'))
                                .where(position_column.gteq(relative_position))
                                .order(position_column.asc)

        find_next_gap(items_with_next_pos, range.last, order: :asc, min_gap: min_gap)
      end

      def find_next_gap(items_with_next_pos, default_end, order:, min_gap: MIN_GAP)
        gap = model_class
          .from(items_with_next_pos, :items)
          .where('next_pos IS NULL OR ABS(pos::bigint - next_pos::bigint) >= ?', min_gap)
          .order(pos: order)
          .pick(:pos, :next_pos)

        return if gap.nil? || gap.first == default_end

        Gap.new(gap.first, gap.second || default_end, ideal_distance: ideal_distance)
      end

      def scoped_items
        object.relative_positioning_scoped_items(ignoring: ignoring)
      end

      def relative_position
        object.relative_position
      end

      private

      # Moves the sequence starting from the current item to the middle of the next gap before it.
      # For example, we have
      #
      #   5 . . . . . 11 12 13 14 [15] 16 . 17
      #               ----------------
      #
      # This moves the sequence [11 12 13 14 15] to [8 9 10 11 12], so we have:
      #
      #   5 . . 8 9 10 11 [12] . . . 16 . 17
      #         --------------
      #
      # Creating a gap to the right of the current item. We can understand this as
      # dividing the 5 spaces between 5 and 11 into two smaller gaps of 2 and 3.
      #
      # As an optimization, the gap can be precalculated and passed to this method.
      #
      # @api private
      # @raises NoSpaceLeft if the sequence cannot be moved
      def move_sequence_before(next_gap: find_next_gap_before, exclude: nil)
        raise NoSpaceLeft unless next_gap.present?

        delta = next_gap.delta

        move_sequence(next_gap.start_pos, relative_position, -delta, exclude: exclude)
      end

      # Moves the sequence starting from the current item to the middle of the next gap after it.
      # For example, we have:
      #
      #   8 . 10 [11] 12 13 14 15 . . . . . 21
      #          ----------------
      #
      # This moves the sequence [11 12 13 14 15] to [14 15 16 17 18], so we have:
      #
      #   8 . 10 . . . [14] 15 16 17 18 . . 21
      #                ----------------
      #
      # Creating a gap to the left of the current item. We can understand this as
      # dividing the 5 spaces between 15 and 21 into two smaller gaps of 3 and 2.
      #
      # As an optimization, the gap can be precalculated and passed to this method.
      #
      # @api private
      # @raises NoSpaceLeft if the sequence cannot be moved
      def move_sequence_after(next_gap: find_next_gap_after, exclude: nil)
        raise NoSpaceLeft unless next_gap.present?

        delta = next_gap.delta

        move_sequence(relative_position, next_gap.start_pos, delta, exclude: exclude)
      end

      def move_sequence(start_pos, end_pos, delta, exclude: nil)
        relation = exclude ? scoped_items.id_not_in(exclude) : scoped_items

        object.update_relative_siblings(relation, start_pos..end_pos, delta)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
