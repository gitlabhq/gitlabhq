# frozen_string_literal: true

class CustomIssueTrackerService < IssueTrackerService
  validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  def default_title
    'Custom Issue Tracker'
  end

  def default_description
    s_('IssueTracker|Custom issue tracker')
  end

  def self.to_param
    'custom_issue_tracker'
  end

  def fields
    [
      { type: 'text', name: 'title', placeholder: title },
      { type: 'text', name: 'description', placeholder: description },
      { type: 'text', name: 'project_url', placeholder: 'Project url', required: true },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url', required: true },
      { type: 'text', name: 'new_issue_url', placeholder: 'New Issue url', required: true }
    ]
  end
end
