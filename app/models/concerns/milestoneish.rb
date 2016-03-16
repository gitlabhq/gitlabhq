module Milestoneish
  def closed_items_count
    issues.closed.size + merge_requests.closed_and_merged.size
  end

  def total_items_count
    issues.size + merge_requests.size
  end

  def complete?
    total_items_count == closed_items_count
  end

  def percent_complete
    ((closed_items_count * 100) / total_items_count).abs
  rescue ZeroDivisionError
    0
  end

  def remaining_days
    return 0 if !due_date || expired?

    (due_date - Date.today).to_i
  end
end
