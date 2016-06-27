class BugzillaService < IssueTrackerService

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'Bugzilla'
    end
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'Bugzilla issue tracker'
    end
  end

  def to_param
    'bugzilla'
  end

  def fields
    [
      { type: 'text', name: 'description', placeholder: description },
      { type: 'text', name: 'project_url', placeholder: 'Project url' },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url' },
      { type: 'text', name: 'new_issue_url', placeholder: 'New Issue url' }
    ]
  end

  def initialize_properties
    self.properties = {} if properties.nil?
  end
end
