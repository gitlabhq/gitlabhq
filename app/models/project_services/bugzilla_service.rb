# frozen_string_literal: true

class BugzillaService < IssueTrackerService
  validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

  def default_title
    'Bugzilla'
  end

  def default_description
    s_('IssueTracker|Bugzilla issue tracker')
  end

  def self.to_param
    'bugzilla'
  end
end
