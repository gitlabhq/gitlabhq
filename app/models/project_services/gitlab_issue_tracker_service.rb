class GitlabIssueTrackerService < IssueTrackerService
  include Gitlab::Routing.url_helpers

  validates :project_url, :issues_url, :new_issue_url, presence: true, url: true, if: :activated?

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  default_value_for :default, true

  def to_param
    'gitlab'
  end

  def project_url
    namespace_project_issues_url(project.namespace, project)
  end

  def new_issue_url
    new_namespace_project_issue_url(namespace_id: project.namespace, project_id: project)
  end

  def issue_url(iid)
    namespace_project_issue_url(namespace_id: project.namespace, project_id: project, id: iid)
  end

  def project_path
    namespace_project_issues_path(project.namespace, project)
  end

  def new_issue_path
    new_namespace_project_issue_path(namespace_id: project.namespace, project_id: project)
  end

  def issue_path(iid)
    namespace_project_issue_path(namespace_id: project.namespace, project_id: project, id: iid)
  end
end
