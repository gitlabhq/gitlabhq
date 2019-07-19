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
  MAX_SEQUENCE_LIMIT = 1000

  class GapNotFound < StandardError
    def message
      'Could not find a gap in the sequence of relative positions.'
    end
  end

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

    # If there is no place to insert an item we need to create one by moving the before item closer
    # to its predecessor. This process will recursively move all the predecessors until we have a place
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

    if before.shift_after?
      before.move_sequence_after
    end

    self.relative_position = self.class.position_between(pos_before, pos_after)
  end

  def move_before(after = self)
    pos_after = after.relative_position
    pos_before = after.prev_relative_position

    if after.shift_before?
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

  # Indicates if there is an item that should be shifted to free the place
  def shift_after?
    next_pos = next_relative_position
    next_pos && (next_pos - relative_position) == 1
  end

  # Indicates if there is an item that should be shifted to free the place
  def shift_before?
    prev_pos = prev_relative_position
    prev_pos && (relative_position - prev_pos) == 1
  end

  def move_sequence_before
    items_to_move = scoped_items_batch.where('relative_position <= ?', relative_position).order('relative_position DESC')
    move_nearest_sequence(items_to_move, MIN_POSITION)
  end

  def move_sequence_after
    items_to_move = scoped_items_batch.where('relative_position >= ?', relative_position).order(:relative_position)
    move_nearest_sequence(items_to_move, MAX_POSITION)
  end

  private

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

  def scoped_items_batch
    scoped_items.limit(MAX_SEQUENCE_LIMIT).select(:id, :relative_position).where.not(id: self.id)
  end

  # Supposing that we have a sequence of positions: 5 11 12 13 14 15,
  # and we want to move another item between 14 and 15, then
  # we shift previous positions at least by one item, but ideally to the middle
  # of the nearest gap. In this case gap is between 5 and 11 so
  # this would move 11 12 13 14 to 8 9 10 11.
  def move_nearest_sequence(items, end_position)
    gap_idx, gap_size = find_gap_in_sequence(items)

    # If we didn't find a gap in the sequence, it's still possible that there
    # are some free positions before the first item
    if gap_idx.nil? && !items.empty? && items.size < MAX_SEQUENCE_LIMIT &&
        items.last.relative_position != end_position

      gap_idx = items.size
      gap_size = end_position - items.last.relative_position
    end

    # The chance that there is a sequence of 1000 positions w/o gap is really
    # low, but it would be good to rebalance all positions in the scope instead
    # of raising an exception:
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/64514#note_192657097
    raise GapNotFound if gap_idx.nil?
    # No shift is needed if gap is next to the item being moved
    return true if gap_idx == 0

    delta = max_delta_for_sequence(gap_size)
    sequence_ids = items.first(gap_idx).map(&:id)
    move_ids_by_delta(sequence_ids, delta)
  end

  def max_delta_for_sequence(gap_size)
    delta = gap_size / 2

    if delta.abs > IDEAL_DISTANCE
      delta = delta < 0 ? -IDEAL_DISTANCE : IDEAL_DISTANCE
    end

    delta
  end

  def move_ids_by_delta(ids, delta)
    self.class.where(id: ids).update_all("relative_position=relative_position+#{delta}")
  end

  def find_gap_in_sequence(items)
    prev = relative_position
    gap = nil

    items.each_with_index do |rec, idx|
      size = rec.relative_position - prev
      if size.abs > 1
        gap = [idx, size]
        break
      end

      prev = rec.relative_position
    end

    gap
  end
end
