# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#

class ProjectHook < WebHook
  belongs_to :project

  attr_accessible :push_events, :issues_events, :merge_requests_events

  scope :push_hooks, -> { where(push_events: true) }
  scope :issue_hooks, -> { where(issues_events: true) }
  scope :merge_request_hooks, -> { where(merge_requests_events: true) }
end
