module RelativePositioning
  extend ActiveSupport::Concern

  MIN_POSITION = 0
  MAX_POSITION = Gitlab::Database::MAX_INT_VALUE

  included do
    after_save :save_positionable_neighbours
  end

  def min_relative_position
    self.class.in_projects(project.id).minimum(:relative_position)
  end

  def max_relative_position
    self.class.in_projects(project.id).maximum(:relative_position)
  end

  def prev_relative_position
    prev_pos = nil

    if self.relative_position
      prev_pos = self.class.
        in_projects(project.id).
        where('relative_position < ?', self.relative_position).
        maximum(:relative_position)
    end

    prev_pos || MIN_POSITION
  end

  def next_relative_position
    next_pos = nil

    if self.relative_position
      next_pos = self.class.
        in_projects(project.id).
        where('relative_position > ?', self.relative_position).
        minimum(:relative_position)
    end

    next_pos || MAX_POSITION
  end

  def move_between(before, after)
    return move_after(before) unless after
    return move_before(after) unless before

    pos_before = before.relative_position
    pos_after = after.relative_position

    if pos_after && (pos_before == pos_after)
      self.relative_position = pos_before
      before.move_before(self)
      after.move_after(self)

      @positionable_neighbours = [before, after]
    else
      self.relative_position = position_between(pos_before, pos_after)
    end
  end

  def move_before(after)
    self.relative_position = position_between(after.prev_relative_position, after.relative_position)
  end

  def move_after(before)
    self.relative_position = position_between(before.relative_position, before.next_relative_position)
  end

  def move_to_end
    self.relative_position = position_between(max_relative_position, MAX_POSITION)
  end

  private

  # This method takes two integer values (positions) and
  # calculates some random position between them. The range is huge as
  # the maximum integer value is 2147483647. Ideally, the calculated value would be
  # exactly between those terminating values, but this will introduce possibility of a race condition
  # so two or more issues can get the same value, we want to avoid that and we also want to avoid
  # using a lock here. If we have two issues with distance more than one thousand, we are OK.
  # Given the huge range of possible values that integer can fit we shoud never face a problem.
  def position_between(pos_before, pos_after)
    pos_before ||= MIN_POSITION
    pos_after ||= MAX_POSITION

    pos_before, pos_after = [pos_before, pos_after].sort

    rand(pos_before.next..pos_after.pred)
  end

  def save_positionable_neighbours
    return unless @positionable_neighbours

    status = @positionable_neighbours.all?(&:save)
    @positionable_neighbours = nil

    status
  end
end
