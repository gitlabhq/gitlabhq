# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#  template   :boolean          default(FALSE)
#

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
    "#{gitlab_url}#{namespace_project_issues_path(project.namespace, project)}"
  end

  def new_issue_url
    "#{gitlab_url}#{new_namespace_project_issue_path(namespace_id: project.namespace, project_id: project)}"
  end

  def issue_url(iid)
    "#{gitlab_url}#{namespace_project_issue_path(namespace_id: project.namespace, project_id: project, id: iid)}"
  end

  private

  def gitlab_url
    Gitlab.config.gitlab.relative_url_root.chomp("/") if Gitlab.config.gitlab.relative_url_root
  end
end
