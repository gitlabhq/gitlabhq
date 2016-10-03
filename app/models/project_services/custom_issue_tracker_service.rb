class CustomIssueTrackerService < IssueTrackerService
  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'Custom Issue Tracker'
    end
  end

  def title=(value)
    self.properties['title'] = value if self.properties
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'Custom issue tracker'
    end
  end

  def to_param
    'custom_issue_tracker'
  end

  def fields
    [
      { type: 'text', name: 'title', placeholder: title },
      { type: 'text', name: 'description', placeholder: description },
      { type: 'text', name: 'project_url', placeholder: 'Project url' },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url' },
      { type: 'text', name: 'new_issue_url', placeholder: 'New Issue url' }
    ]
  end
end
