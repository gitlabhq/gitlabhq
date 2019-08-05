# frozen_string_literal: true

# This module makes it possible to handle items as a list, where the order of items can be easily altered
# Requirements:
#
# - Only works for ActiveRecord models
# - relative_position integer field must present on the model
# - This module uses GROUP BY: the model should have a parent relation, example: project -> issues, project is the parent relation (issues table has a parent_id column)
#
# Setup like this in the body of your class:
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

  MIN_POSITION = 0
  START_POSITION = Gitlab::Database::MAX_INT_VALUE / 2
  MAX_POSITION = Gitlab::Database::MAX_INT_VALUE
  IDEAL_DISTANCE = 500

  class_methods do
    def move_nulls_to_end(objects)
      objects = objects.reject(&:relative_position)

      return if objects.empty?

      max_relative_position = objects.first.max_relative_position

      self.transaction do
        objects.each do |object|
          relative_position = position_between(max_relative_position || START_POSITION, MAX_POSITION)
          object.relative_position = relative_position
          max_relative_position = relative_position
          object.save(touch: false)
        end
      end
    end

    # This method takes two integer values (positions) and
    # calculates the position between them. The range is huge as
    # the maximum integer value is 2147483647. We are incrementing position by IDEAL_DISTANCE * 2 every time
    # when we have enough space. If distance is less then IDEAL_DISTANCE we are calculating an average number
    def position_between(pos_before, pos_after)
      pos_before ||= MIN_POSITION
      pos_after ||= MAX_POSITION

      pos_before, pos_after = [pos_before, pos_after].sort

      halfway = (pos_after + pos_before) / 2
      distance_to_halfway = pos_after - halfway

      if distance_to_halfway < IDEAL_DISTANCE
        halfway
      else
        if pos_before == MIN_POSITION
          pos_after - IDEAL_DISTANCE
        elsif pos_after == MAX_POSITION
          pos_before + IDEAL_DISTANCE
        else
          halfway
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

  def prev_relative_position
    prev_pos = nil

    if self.relative_position
      prev_pos = max_relative_position do |relation|
        relation.where('relative_position < ?', self.relative_position)
      end
    end

    prev_pos
  end

  def next_relative_position
    next_pos = nil

    if self.relative_position
      next_pos = min_relative_position do |relation|
        relation.where('relative_position > ?', self.relative_position)
      end
    end

    next_pos
  end

  def move_between(before, after)
    return move_after(before) unless after
    return move_before(after) unless before

    # If there is no place to insert an item we need to create one by moving the item
    # before this and all preceding items until there is a gap
    before, after = after, before if after.relative_position < before.relative_position
    if (after.relative_position - before.relative_position) < 2
      after.move_sequence_before
      before.reset
    end

    self.relative_position = self.class.position_between(before.relative_position, after.relative_position)
  end

  def move_after(before = self)
    pos_before = before.relative_position
    pos_after = before.next_relative_position

    if pos_after && (pos_after - pos_before) < 2
      before.move_sequence_after
    end

    self.relative_position = self.class.position_between(pos_before, pos_after)
  end

  def move_before(after = self)
    pos_after = after.relative_position
    pos_before = after.prev_relative_position

    if pos_before && (pos_after - pos_before) < 2
      after.move_sequence_before
    end

    self.relative_position = self.class.position_between(pos_before, pos_after)
  end

  def move_to_end
    self.relative_position = self.class.position_between(max_relative_position || START_POSITION, MAX_POSITION)
  end

  def move_to_start
    self.relative_position = self.class.position_between(min_relative_position || START_POSITION, MIN_POSITION)
  end

  # Moves the sequence before the current item to the middle of the next gap
  # For example, we have 5 11 12 13 14 15 and the current item is 15
  # This moves the sequence 11 12 13 14 to 8 9 10 11
  def move_sequence_before
    next_gap = find_next_gap_before
    delta = optimum_delta_for_gap(next_gap)

    move_sequence(next_gap[:start], relative_position, -delta)
  end

  # Moves the sequence after the current item to the middle of the next gap
  # For example, we have 11 12 13 14 15 21 and the current item is 11
  # This moves the sequence 12 13 14 15 to 15 16 17 18
  def move_sequence_after
    next_gap = find_next_gap_after
    delta = optimum_delta_for_gap(next_gap)

    move_sequence(relative_position, next_gap[:start], delta)
  end

  private

  # Supposing that we have a sequence of items: 1 5 11 12 13 and the current item is 13
  # This would return: `{ start: 11, end: 5 }`
  def find_next_gap_before
    items_with_next_pos = scoped_items
                            .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position DESC) AS next_pos')
                            .where('relative_position <= ?', relative_position)
                            .order(relative_position: :desc)

    find_next_gap(items_with_next_pos).tap do |gap|
      gap[:end] ||= MIN_POSITION
    end
  end

  # Supposing that we have a sequence of items: 13 14 15 20 24 and the current item is 13
  # This would return: `{ start: 15, end: 20 }`
  def find_next_gap_after
    items_with_next_pos = scoped_items
                            .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position ASC) AS next_pos')
                            .where('relative_position >= ?', relative_position)
                            .order(:relative_position)

    find_next_gap(items_with_next_pos).tap do |gap|
      gap[:end] ||= MAX_POSITION
    end
  end

  def find_next_gap(items_with_next_pos)
    gap = self.class.from(items_with_next_pos, :items_with_next_pos)
                    .where('ABS(pos - next_pos) > 1 OR next_pos IS NULL')
                    .limit(1)
                    .pluck(:pos, :next_pos)
                    .first

    { start: gap[0], end: gap[1] }
  end

  def optimum_delta_for_gap(gap)
    delta = ((gap[:start] - gap[:end]) / 2.0).abs.ceil

    [delta, IDEAL_DISTANCE].min
  end

  def move_sequence(start_pos, end_pos, delta)
    scoped_items
      .where.not(id: self.id)
      .where('relative_position BETWEEN ? AND ?', start_pos, end_pos)
      .update_all("relative_position = relative_position + #{delta}")
  end

  def calculate_relative_position(calculation)
    # When calculating across projects, this is much more efficient than
    # MAX(relative_position) without the GROUP BY, due to index usage:
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/54276#note_119340977
    relation = scoped_items
                 .order(Gitlab::Database.nulls_last_order('position', 'DESC'))
                 .group(self.class.relative_positioning_parent_column)
                 .limit(1)

    relation = yield relation if block_given?

    relation
      .pluck(self.class.relative_positioning_parent_column, Arel.sql("#{calculation}(relative_position) AS position"))
      .first&.
      last
  end

  def scoped_items
    self.class.relative_positioning_query_base(self)
  end
end
