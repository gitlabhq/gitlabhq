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

class JiraService < IssueTrackerService
  include Rails.application.routes.url_helpers

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  def help
    issue_tracker_link =  help_page_path("integration", "external-issue-tracker")

    line1 = "Setting `project_url`, `issues_url` and `new_issue_url` will "\
    "allow a user to easily navigate to the Jira issue tracker. "\
    "See the [integration doc](#{issue_tracker_link}) for details."

    line2 = 'Support for referencing commits and automatic closing of Jira issues directly ' \
    'from GitLab is [available in GitLab EE.](http://doc.gitlab.com/ee/integration/jira.html)'

    [line1, line2].join("\n\n")
  end

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'JIRA'
    end
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'Jira issue tracker'
    end
  end

  def to_param
    'jira'
  end
end
