module RelativePositioning
  extend ActiveSupport::Concern

  MIN_POSITION = 0
  START_POSITION = Gitlab::Database::MAX_INT_VALUE / 2
  MAX_POSITION = Gitlab::Database::MAX_INT_VALUE
  IDEAL_DISTANCE = 500

  included do
    after_save :save_positionable_neighbours
  end

  def min_relative_position
    self.class.in_parents(parent_ids).minimum(:relative_position)
  end

  def max_relative_position
    self.class.in_parents(parent_ids).maximum(:relative_position)
  end

  def prev_relative_position
    prev_pos = nil

    if self.relative_position
      prev_pos = self.class
        .in_parents(parent_ids)
        .where('relative_position < ?', self.relative_position)
        .maximum(:relative_position)
    end

    prev_pos
  end

  def next_relative_position
    next_pos = nil

    if self.relative_position
      next_pos = self.class
        .in_parents(parent_ids)
        .where('relative_position > ?', self.relative_position)
        .minimum(:relative_position)
    end

    next_pos
  end

  def move_between(before, after)
    return move_after(before) unless after
    return move_before(after) unless before

    # If there is no place to insert an issue we need to create one by moving the before issue closer
    # to its predecessor. This process will recursively move all the predecessors until we have a place
    if (after.relative_position - before.relative_position) < 2
      before.move_before
      @positionable_neighbours = [before] # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    self.relative_position = position_between(before.relative_position, after.relative_position)
  end

  def move_after(before = self)
    pos_before = before.relative_position
    pos_after = before.next_relative_position

    if before.shift_after?
      issue_to_move = self.class.in_parents(parent_ids).find_by!(relative_position: pos_after)
      issue_to_move.move_after
      @positionable_neighbours = [issue_to_move] # rubocop:disable Gitlab/ModuleWithInstanceVariables

      pos_after = issue_to_move.relative_position
    end

    self.relative_position = position_between(pos_before, pos_after)
  end

  def move_before(after = self)
    pos_after = after.relative_position
    pos_before = after.prev_relative_position

    if after.shift_before?
      issue_to_move = self.class.in_parents(parent_ids).find_by!(relative_position: pos_before)
      issue_to_move.move_before
      @positionable_neighbours = [issue_to_move] # rubocop:disable Gitlab/ModuleWithInstanceVariables

      pos_before = issue_to_move.relative_position
    end

    self.relative_position = position_between(pos_before, pos_after)
  end

  def move_to_end
    self.relative_position = position_between(max_relative_position || START_POSITION, MAX_POSITION)
  end

  def move_to_start
    self.relative_position = position_between(min_relative_position || START_POSITION, MIN_POSITION)
  end

  # Indicates if there is an issue that should be shifted to free the place
  def shift_after?
    next_pos = next_relative_position
    next_pos && (next_pos - relative_position) == 1
  end

  # Indicates if there is an issue that should be shifted to free the place
  def shift_before?
    prev_pos = prev_relative_position
    prev_pos && (relative_position - prev_pos) == 1
  end

  private

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

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def save_positionable_neighbours
    return unless @positionable_neighbours

    status = @positionable_neighbours.all?(&:save)
    @positionable_neighbours = nil

    status
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
