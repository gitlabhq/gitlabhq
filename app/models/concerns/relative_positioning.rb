# frozen_string_literal: true

# This module makes it possible to handle items as a list, where the order of items can be easily altered
# Requirements:
#
# The model must have the following named columns:
#  - id: integer
#  - relative_position: integer
#
# The model must support a concept of siblings via a child->parent relationship,
# to enable rebalancing and `GROUP BY` in queries.
# - example: project -> issues, project is the parent relation (issues table has a parent_id column)
#
# Two class methods must be defined when including this concern:
#
#     include RelativePositioning
#
#     # base query used for the position calculation
#     def self.relative_positioning_query_base(issue)
#       where(deleted: false)
#     end
#
#     # column that should be used in GROUP BY
#     def self.relative_positioning_parent_column
#       :project_id
#     end
#
module RelativePositioning
  extend ActiveSupport::Concern

  STEPS = 10
  IDEAL_DISTANCE = 2**(STEPS - 1) + 1

  MIN_POSITION = Gitlab::Database::MIN_INT_VALUE
  START_POSITION = 0
  MAX_POSITION = Gitlab::Database::MAX_INT_VALUE

  MAX_GAP = IDEAL_DISTANCE * 2
  MIN_GAP = 2

  NoSpaceLeft = Class.new(StandardError)

  class_methods do
    def move_nulls_to_end(objects)
      move_nulls(objects, at_end: true)
    end

    def move_nulls_to_start(objects)
      move_nulls(objects, at_end: false)
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
    # This class method should only be called by instance methods of this module, which
    # include handling for minimum gap size.
    #
    # @raises NoSpaceLeft
    # @api private
    def position_between(pos_before, pos_after)
      pos_before ||= MIN_POSITION
      pos_after ||= MAX_POSITION

      pos_before, pos_after = [pos_before, pos_after].sort

      gap_width = pos_after - pos_before
      midpoint = [pos_after - 1, pos_before + (gap_width / 2)].min

      if gap_width < MIN_GAP
        raise NoSpaceLeft
      elsif gap_width > MAX_GAP
        if pos_before == MIN_POSITION
          pos_after - IDEAL_DISTANCE
        elsif pos_after == MAX_POSITION
          pos_before + IDEAL_DISTANCE
        else
          midpoint
        end
      else
        midpoint
      end
    end

    private

    # @api private
    def gap_size(object, gaps:, at_end:, starting_from:)
      total_width = IDEAL_DISTANCE * gaps
      size = if at_end && starting_from + total_width >= MAX_POSITION
               (MAX_POSITION - starting_from) / gaps
             elsif !at_end && starting_from - total_width <= MIN_POSITION
               (starting_from - MIN_POSITION) / gaps
             else
               IDEAL_DISTANCE
             end

      # Shift max elements leftwards if there isn't enough space
      return [size, starting_from] if size >= MIN_GAP

      order = at_end ? :desc : :asc
      terminus = object
        .send(:relative_siblings) # rubocop:disable GitlabSecurity/PublicSend
        .where('relative_position IS NOT NULL')
        .order(relative_position: order)
        .first

      if at_end
        terminus.move_sequence_before(true)
        max_relative_position = terminus.reset.relative_position
        [[(MAX_POSITION - max_relative_position) / gaps, IDEAL_DISTANCE].min, max_relative_position]
      else
        terminus.move_sequence_after(true)
        min_relative_position = terminus.reset.relative_position
        [[(min_relative_position - MIN_POSITION) / gaps, IDEAL_DISTANCE].min, min_relative_position]
      end
    end

    # @api private
    # @param [Array<RelativePositioning>] objects The objects to give positions to. The relative
    #                                             order will be preserved (i.e. when this method returns,
    #                                             objects.first.relative_position < objects.last.relative_position)
    # @param [Boolean] at_end: The placement.
    #                          If `true`, then all objects with `null` positions are placed _after_
    #                          all siblings with positions. If `false`, all objects with `null`
    #                          positions are placed _before_ all siblings with positions.
    def move_nulls(objects, at_end:)
      objects = objects.reject(&:relative_position)
      return if objects.empty?

      representative = objects.first
      number_of_gaps = objects.size + 1 # 1 at left, one between each, and one at right
      position = if at_end
                   representative.max_relative_position
                 else
                   representative.min_relative_position
                 end

      position ||= START_POSITION # If there are no positioned siblings, start from START_POSITION

      gap, position = gap_size(representative, gaps: number_of_gaps, at_end: at_end, starting_from: position)

      # Raise if we could not make enough space
      raise NoSpaceLeft if gap < MIN_GAP

      indexed = objects.each_with_index.to_a
      starting_from = at_end ? position : position - (gap * number_of_gaps)

      # Some classes are polymorphic, and not all siblings are in the same table.
      by_model = indexed.group_by { |pair| pair.first.class }

      by_model.each do |model, pairs|
        model.transaction do
          pairs.each_slice(100) do |batch|
            # These are known to be integers, one from the DB, and the other
            # calculated by us, and thus safe to interpolate
            values = batch.map do |obj, i|
              pos = starting_from + gap * (i + 1)
              obj.relative_position = pos
              "(#{obj.id}, #{pos})"
            end.join(', ')

            model.connection.exec_query(<<~SQL, "UPDATE #{model.table_name} positions")
              WITH cte(cte_id, new_pos) AS (
               SELECT *
               FROM (VALUES #{values}) as t (id, pos)
              )
              UPDATE #{model.table_name}
              SET relative_position = cte.new_pos
              FROM cte
              WHERE cte_id = id
            SQL
          end
        end
      end
    end
  end

  def min_relative_position(&block)
    calculate_relative_position('MIN', &block)
  end

  def max_relative_position(&block)
    calculate_relative_position('MAX', &block)
  end

  def prev_relative_position(ignoring: nil)
    prev_pos = nil

    if self.relative_position
      prev_pos = max_relative_position do |relation|
        relation = relation.id_not_in(ignoring.id) if ignoring.present?
        relation.where('relative_position < ?', self.relative_position)
      end
    end

    prev_pos
  end

  def next_relative_position(ignoring: nil)
    next_pos = nil

    if self.relative_position
      next_pos = min_relative_position do |relation|
        relation = relation.id_not_in(ignoring.id) if ignoring.present?
        relation.where('relative_position > ?', self.relative_position)
      end
    end

    next_pos
  end

  def move_between(before, after)
    return move_after(before) unless after
    return move_before(after) unless before

    before, after = after, before if after.relative_position < before.relative_position

    pos_left = before.relative_position
    pos_right = after.relative_position

    if pos_right - pos_left < MIN_GAP
      # Not enough room! Make space by shifting all previous elements to the left
      # if there is enough space, else to the right
      gap = after.send(:find_next_gap_before) # rubocop:disable GitlabSecurity/PublicSend

      if gap.present?
        after.move_sequence_before(next_gap: gap)
        pos_left -= optimum_delta_for_gap(gap)
      else
        before.move_sequence_after
        pos_right = after.reset.relative_position
      end
    end

    new_position = self.class.position_between(pos_left, pos_right)

    self.relative_position = new_position
  end

  def move_after(before = self)
    pos_before = before.relative_position
    pos_after = before.next_relative_position(ignoring: self)

    if pos_before == MAX_POSITION || gap_too_small?(pos_after, pos_before)
      gap = before.send(:find_next_gap_after) # rubocop:disable GitlabSecurity/PublicSend

      if gap.nil?
        before.move_sequence_before(true)
        pos_before = before.reset.relative_position
      else
        before.move_sequence_after(next_gap: gap)
        pos_after += optimum_delta_for_gap(gap)
      end
    end

    self.relative_position = self.class.position_between(pos_before, pos_after)
  end

  def move_before(after = self)
    pos_after = after.relative_position
    pos_before = after.prev_relative_position(ignoring: self)

    if pos_after == MIN_POSITION || gap_too_small?(pos_before, pos_after)
      gap = after.send(:find_next_gap_before) # rubocop:disable GitlabSecurity/PublicSend

      if gap.nil?
        after.move_sequence_after(true)
        pos_after = after.reset.relative_position
      else
        after.move_sequence_before(next_gap: gap)
        pos_before -= optimum_delta_for_gap(gap)
      end
    end

    self.relative_position = self.class.position_between(pos_before, pos_after)
  end

  def move_to_end
    max_pos = max_relative_position

    if max_pos.nil?
      self.relative_position = START_POSITION
    elsif gap_too_small?(max_pos, MAX_POSITION)
      max = relative_siblings.order(Gitlab::Database.nulls_last_order('relative_position', 'DESC')).first
      max.move_sequence_before(true)
      max.reset
      self.relative_position = self.class.position_between(max.relative_position, MAX_POSITION)
    else
      self.relative_position = self.class.position_between(max_pos, MAX_POSITION)
    end
  end

  def move_to_start
    min_pos = min_relative_position

    if min_pos.nil?
      self.relative_position = START_POSITION
    elsif gap_too_small?(min_pos, MIN_POSITION)
      min = relative_siblings.order(Gitlab::Database.nulls_last_order('relative_position', 'ASC')).first
      min.move_sequence_after(true)
      min.reset
      self.relative_position = self.class.position_between(MIN_POSITION, min.relative_position)
    else
      self.relative_position = self.class.position_between(MIN_POSITION, min_pos)
    end
  end

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

    delta = optimum_delta_for_gap(next_gap)

    move_sequence(next_gap[:start], relative_position, -delta, include_self)
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

    delta = optimum_delta_for_gap(next_gap)

    move_sequence(relative_position, next_gap[:start], delta, include_self)
  end

  private

  def gap_too_small?(pos_a, pos_b)
    return false unless pos_a && pos_b

    (pos_a - pos_b).abs < MIN_GAP
  end

  # Find the first suitable gap to the left of the current position.
  #
  # Satisfies the relations:
  #  - gap[:start] <= relative_position
  #  - abs(gap[:start] - gap[:end]) >= MIN_GAP
  #  - MIN_POSITION <= gap[:start] <= MAX_POSITION
  #  - MIN_POSITION <= gap[:end] <= MAX_POSITION
  #
  # Supposing that the current item is 13, and we have a sequence of items:
  #
  #   1 . . . 5 . . . . 11 12 [13] 14 . . 17
  #           ^---------^
  #
  # Then we return: `{ start: 11, end: 5 }`
  #
  # Here start refers to the end of the gap closest to the current item.
  def find_next_gap_before
    items_with_next_pos = scoped_items
                            .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position DESC) AS next_pos')
                            .where('relative_position <= ?', relative_position)
                            .order(relative_position: :desc)

    find_next_gap(items_with_next_pos, MIN_POSITION)
  end

  # Find the first suitable gap to the right of the current position.
  #
  # Satisfies the relations:
  #  - gap[:start] >= relative_position
  #  - abs(gap[:start] - gap[:end]) >= MIN_GAP
  #  - MIN_POSITION <= gap[:start] <= MAX_POSITION
  #  - MIN_POSITION <= gap[:end] <= MAX_POSITION
  #
  # Supposing the current item is 13, and that we have a sequence of items:
  #
  #   9 . . . [13] 14 15 . . . . 20 . . . 24
  #                    ^---------^
  #
  # Then we return: `{ start: 15, end: 20 }`
  #
  # Here start refers to the end of the gap closest to the current item.
  def find_next_gap_after
    items_with_next_pos = scoped_items
                            .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position ASC) AS next_pos')
                            .where('relative_position >= ?', relative_position)
                            .order(:relative_position)

    find_next_gap(items_with_next_pos, MAX_POSITION)
  end

  def find_next_gap(items_with_next_pos, end_is_nil)
    gap = self.class
      .from(items_with_next_pos, :items)
      .where('next_pos IS NULL OR ABS(pos::bigint - next_pos::bigint) >= ?', MIN_GAP)
      .limit(1)
      .pluck(:pos, :next_pos)
      .first

    return if gap.nil? || gap.first == end_is_nil

    { start: gap.first, end: gap.second || end_is_nil }
  end

  def optimum_delta_for_gap(gap)
    delta = ((gap[:start] - gap[:end]) / 2.0).abs.ceil

    [delta, IDEAL_DISTANCE].min
  end

  def move_sequence(start_pos, end_pos, delta, include_self = false)
    relation = include_self ? scoped_items : relative_siblings

    relation
      .where('relative_position BETWEEN ? AND ?', start_pos, end_pos)
      .update_all("relative_position = relative_position + #{delta}")
  end

  def calculate_relative_position(calculation)
    # When calculating across projects, this is much more efficient than
    # MAX(relative_position) without the GROUP BY, due to index usage:
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/54276#note_119340977
    relation = scoped_items
                 .order(Gitlab::Database.nulls_last_order('position', 'DESC'))
                 .group(self.class.relative_positioning_parent_column)
                 .limit(1)

    relation = yield relation if block_given?

    relation
      .pluck(self.class.relative_positioning_parent_column, Arel.sql("#{calculation}(relative_position) AS position"))
      .first&.last
  end

  def relative_siblings(relation = scoped_items)
    relation.id_not_in(id)
  end

  def scoped_items
    self.class.relative_positioning_query_base(self)
  end
end
