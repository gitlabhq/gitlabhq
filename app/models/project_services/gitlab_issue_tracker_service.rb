class GitlabIssueTrackerService < IssueTrackerService
  include Gitlab::Routing

  validates :project_url, :issues_url, :new_issue_url, presence: true, url: true, if: :activated?

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  default_value_for :default, true

  def self.to_param
    'gitlab'
  end

  def project_url
    project_issues_url(project)
  end

  def new_issue_url
    new_project_issue_url(project)
  end

  def issue_url(iid)
    project_issue_url(project, id: iid)
  end

  def issue_tracker_path
    project_issues_path(project)
  end

  def new_issue_path
    new_project_issue_path(project)
  end

  def issue_path(iid)
    project_issue_path(project, id: iid)
  end
end
