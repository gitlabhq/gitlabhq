# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

class JiraService < IssueTrackerService

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

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
