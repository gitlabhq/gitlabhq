module RelativePositioning
  extend ActiveSupport::Concern

  MIN_POSITION = 0
  MAX_POSITION = Gitlab::Database::MAX_INT_VALUE

  def min_relative_position
    self.class.in_projects(project.id).minimum(:relative_position)
  end

  def max_relative_position
    self.class.in_projects(project.id).maximum(:relative_position)
  end

  def move_between(before, after)
    return move_to_end unless after
    return move_to_top unless before

    pos_before = before.relative_position
    pos_after = after.relative_position

    if pos_after && (pos_before == pos_after)
      self.relative_position = pos_before
      before.decrement! :relative_position
      after.increment! :relative_position
    else
      self.relative_position = position_between(pos_before, pos_after)
    end
  end

  def move_to_top
    self.relative_position = position_between(MIN_POSITION, min_relative_position)
  end

  def move_to_end
    self.relative_position = position_between(max_relative_position, MAX_POSITION)
  end

  def move_between!(*args)
    move_between(*args) && save!
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
end
