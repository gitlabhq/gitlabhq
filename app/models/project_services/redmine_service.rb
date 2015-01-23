class RedmineService < IssueTrackerService

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  def title
    'Redmine'
  end

  def description
    'Redmine issue tracker'
  end

  def to_param
    'redmine'
  end

  def fields
    [
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
    Gitlab.config.issues_tracker['redmine']
  end

  def set_project_url
    id = self.project.issue_tracker_id
    if id
      issues_tracker['project_url'].gsub(":issue_tracker_id", id)
    else
      issues_tracker['project_url']
    end
  end
end
