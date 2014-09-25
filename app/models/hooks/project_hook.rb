# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  tag_push_events       :boolean          default(FALSE)
#

class ProjectHook < WebHook
  belongs_to :project

  scope :push_hooks, -> { where(push_events: true) }
  scope :tag_push_hooks, -> { where(tag_push_events: true) }
  scope :issue_hooks, -> { where(issues_events: true) }
  scope :merge_request_hooks, -> { where(merge_requests_events: true) }
end
