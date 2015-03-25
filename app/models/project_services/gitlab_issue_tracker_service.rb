# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

class GitlabIssueTrackerService < IssueTrackerService
  include Rails.application.routes.url_helpers

  default_url_options[:host]     = Gitlab.config.gitlab.host
  default_url_options[:protocol] = Gitlab.config.gitlab.protocol
  default_url_options[:port]     = Gitlab.config.gitlab.port unless Gitlab.config.gitlab_on_standard_port?
  default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  def default?
    true
  end

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
