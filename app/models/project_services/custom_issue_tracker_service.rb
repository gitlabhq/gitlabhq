# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string
#  title                 :string
#  project_id            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  active                :boolean          not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#  category              :string           default("common"), not null
#  default               :boolean          default(FALSE)
#  wiki_page_events      :boolean          default(TRUE)
#

class CustomIssueTrackerService < IssueTrackerService

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'Custom Issue Tracker'
    end
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'Custom issue tracker'
    end
  end

  def to_param
    'custom_issue_tracker'
  end

  def fields
    [
      { type: 'text', name: 'title', placeholder: title },
      { type: 'text', name: 'description', placeholder: description },
      { type: 'text', name: 'project_url', placeholder: 'Project url' },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url' },
      { type: 'text', name: 'new_issue_url', placeholder: 'New Issue url' }
    ]
  end

  def initialize_properties
    self.properties = {} if properties.nil?
  end
end
