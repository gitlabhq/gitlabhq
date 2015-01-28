class IssueTrackerService < Service

  validates :project_url, :issues_url, :new_issue_url, presence: true, if: :activated?

  def category
    :issue_tracker
  end

  def default?
    false
  end

  def project_url
    # implement inside child
  end

  def issues_url
    # implement inside child
  end

  def new_issue_url
    # implement inside child
  end

  def fields
    [
      { type: 'text', name: 'description', placeholder: description },
      { type: 'text', name: 'project_url', placeholder: 'Project url' },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url'},
      { type: 'text', name: 'new_issue_url', placeholder: 'New Issue url'}
    ]
  end

  def initialize_properties
    if properties.nil?
      if enabled_in_gitlab_config
        self.properties = {
          title: issues_tracker['title'],
          project_url: set_project_url,
          issues_url: issues_tracker['issues_url'],
          new_issue_url: issues_tracker['new_issue_url']
        }
      else
        self.properties = {}
      end
    end
  end

  private

  def enabled_in_gitlab_config
    Gitlab.config.issues_tracker &&
    Gitlab.config.issues_tracker.values.any? &&
    issues_tracker
  end

  def issues_tracker
    Gitlab.config.issues_tracker[to_param]
  end

  def set_project_url
    id = self.project.issues_tracker_id

    if id
      issues_tracker['project_url'].gsub(":issues_tracker_id", id)
    else
      issues_tracker['project_url']
    end
  end
end
