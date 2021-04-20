# frozen_string_literal: true

class CustomIssueTrackerService < IssueTrackerService
  validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

  def title
    'Custom Issue Tracker'
  end

  def description
    s_('IssueTracker|Custom issue tracker')
  end

  def self.to_param
    'custom_issue_tracker'
  end

  def fields
    [
      { type: 'text', name: 'project_url', title: _('Project URL'), required: true },
      { type: 'text', name: 'issues_url', title: s_('ProjectService|Issue URL'), required: true },
      { type: 'text', name: 'new_issue_url', title: s_('ProjectService|New issue URL'), required: true }
    ]
  end
end
