class GitlabIssueTrackerService < IssueTrackerService
  include Rails.application.routes.url_helpers
  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url


  def default?
    true
  end

  def to_param
    'gitlab'
  end

  def project_url
    project_issues_path(project)
  end

  def new_issue_url
    new_project_issue_path project_id: project
  end

  def issue_url(iid)
    "#{Gitlab.config.gitlab.url}#{project_issue_path(project_id: project, id: iid)}"
  end
end
