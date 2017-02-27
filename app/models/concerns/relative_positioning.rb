module RelativePositioning
  extend ActiveSupport::Concern

  MIN_POSITION = Float::MIN
  MAX_POSITION = Float::MAX

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
    return move_nowhere unless before || after
    return move_after(before) if before && !after
    return move_before(after) if after && !before

    pos_before = before.relative_position
    pos_after = after.relative_position

    if pos_before && pos_after
      if pos_before == pos_after
        pos = pos_before

        self.relative_position = pos
        before.move_before(self)
        after.move_after(self)
        @positionable_neighbours = [before, after]
      else
        self.relative_position = position_between(pos_before, pos_after)
      end
    elsif pos_before
      self.move_after(before)
      after.move_after(self)
      @positionable_neighbours = [after]
    elsif pos_after
      self.move_before(after)
      before.move_before(self)
      @positionable_neighbours = [before]
    else
      move_to_end
      before.move_before(self)
      after.move_after(self)
      @positionable_neighbours = [before, after]
    end
  end

  def move_before(after)
    pos_after = after.relative_position
    if pos_after
      self.relative_position = position_between(MIN_POSITION, pos_after)
    else
      move_to_end
      after.move_after(self)
      @positionable_neighbours = [after]
    end
  end

  def move_after(before)
    pos_before = before.relative_position
    if pos_before
      self.relative_position = position_between(pos_before, MAX_POSITION)
    else
      move_to_end
      before.move_before(self)
      @positionable_neighbours = [before]
    end
  end

  def move_nowhere
    self.relative_position = nil
  end

  def move_to_front
    self.relative_position = position_between(MIN_POSITION, min_relative_position || MAX_POSITION)
  end

  def move_to_end
    self.relative_position = position_between(max_relative_position || MIN_POSITION, MAX_POSITION)
  end

  def move_between!(*args)
    move_between(*args) && save!
  end

  private

  def position_between(pos_before, pos_after)
    pos_before, pos_after = [pos_before, pos_after].sort

    rand(pos_before.next_float..pos_after.prev_float)
  end

  def save_positionable_neighbours
    return unless @positionable_neighbours

    @positionable_neighbours.each(&:save)
    @positionable_neighbours = nil

    true
  end
end
