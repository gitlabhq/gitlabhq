class ConvertClosedToStateInIssue < ActiveRecord::Migration
  def up
    Issue.transaction do
      Issue.find_each do |issue|
        issue.state = issue.closed? ? :closed : :opened
        issue.save
      end
    end
  end

  def down
    Issue.transaction do
      Issue.find_each do |issue|
        issue.closed = issue.closed?
        issue.save
      end
    end
  end
end
