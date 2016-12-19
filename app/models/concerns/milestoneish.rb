module Milestoneish
  def closed_items_count(user)
    issues_visible_to_user(user).closed.size + merge_requests.closed_and_merged.size
  end

  def total_items_count(user)
    issues_visible_to_user(user).size + merge_requests.size
  end

  def complete?(user)
    total_items_count(user) > 0 && total_items_count(user) == closed_items_count(user)
  end

  def percent_complete(user)
    ((closed_items_count(user) * 100) / total_items_count(user)).abs
  rescue ZeroDivisionError
    0
  end

  def remaining_days
    return 0 if !due_date || expired?

    (due_date - Date.today).to_i
  end

  def elapsed_days
    return 0 if !start_date || start_date.future?

    (Date.today - start_date).to_i
  end

  def issues_visible_to_user(user)
    IssuesFinder.new(user).execute.where(id: issues)
  end

  def upcoming?
    start_date && start_date.future?
  end

  def expires_at
    if due_date
      if due_date.past?
        "expired on #{due_date.to_s(:medium)}"
      else
        "expires on #{due_date.to_s(:medium)}"
      end
    end
  end

  def expired?
    due_date && due_date.past?
  end
end
