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
end
