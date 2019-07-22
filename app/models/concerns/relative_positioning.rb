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

  included do
    after_save :save_positionable_neighbours
  end

  class_methods do
    def move_to_end(objects)
      objects = objects.reject(&:relative_position)

      return if objects.empty?

      max_relative_position = objects.first.max_relative_position

      self.transaction do
        objects.each do |object|
          relative_position = position_between(max_relative_position, MAX_POSITION)
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
    if (after.relative_position - before.relative_position) < 2
      before.move_before
      @positionable_neighbours = [before] # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    self.relative_position = self.class.position_between(before.relative_position, after.relative_position)
  end

  def move_after(before = self)
    pos_before = before.relative_position
    pos_after = before.next_relative_position

    if before.shift_after?
      item_to_move = self.class.relative_positioning_query_base(self).find_by!(relative_position: pos_after)
      item_to_move.move_after
      @positionable_neighbours = [item_to_move] # rubocop:disable Gitlab/ModuleWithInstanceVariables

      pos_after = item_to_move.relative_position
    end

    self.relative_position = self.class.position_between(pos_before, pos_after)
  end

  def move_before(after = self)
    pos_after = after.relative_position
    pos_before = after.prev_relative_position

    if after.shift_before?
      item_to_move = self.class.relative_positioning_query_base(self).find_by!(relative_position: pos_before)
      item_to_move.move_before
      @positionable_neighbours = [item_to_move] # rubocop:disable Gitlab/ModuleWithInstanceVariables

      pos_before = item_to_move.relative_position
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

  private

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def save_positionable_neighbours
    return unless @positionable_neighbours

    status = @positionable_neighbours.all? { |item| item.save(touch: false) }
    @positionable_neighbours = nil

    status
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def calculate_relative_position(calculation)
    # When calculating across projects, this is much more efficient than
    # MAX(relative_position) without the GROUP BY, due to index usage:
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/54276#note_119340977
    relation = self.class.relative_positioning_query_base(self)
                 .order(Gitlab::Database.nulls_last_order('position', 'DESC'))
                 .group(self.class.relative_positioning_parent_column)
                 .limit(1)

    relation = yield relation if block_given?

    relation
      .pluck(self.class.relative_positioning_parent_column, Arel.sql("#{calculation}(relative_position) AS position"))
      .first&.
      last
  end
end
