class ConvertClosedToStateInIssue < ActiveRecord::Migration
  def up
    Issue.transaction do
      Issue.where(closed: true).update_all("state = 'closed'")
      Issue.where(closed: false).update_all("state = 'opened'")
    end
  end

  def down
    Issue.transaction do
      Issue.where(state: :closed).update_all("closed = 1")
    end
  end
end
