# == Schema Information
#
# Table name: web_hooks
#
#  id                      :integer          not null, primary key
#  url                     :string(2000)
#  project_id              :integer
#  created_at              :datetime
#  updated_at              :datetime
#  type                    :string(255)      default("ProjectHook")
#  service_id              :integer
#  push_events             :boolean          default(TRUE), not null
#  issues_events           :boolean          default(FALSE), not null
#  merge_requests_events   :boolean          default(FALSE), not null
#  tag_push_events         :boolean          default(FALSE)
#  group_id                :integer
#  note_events             :boolean          default(FALSE), not null
#  enable_ssl_verification :boolean          default(TRUE)
#  build_events            :boolean          default(FALSE), not null
#  token                   :string
#

class ProjectHook < WebHook
  include CustomModelNaming

  self.singular_route_key = :hook

  belongs_to :project

  scope :issue_hooks, -> { where(issues_events: true) }
  scope :note_hooks, -> { where(note_events: true) }
  scope :merge_request_hooks, -> { where(merge_requests_events: true) }
  scope :build_hooks, -> { where(build_events: true) }
  scope :wiki_page_hooks, ->  { where(wiki_page_events: true) }
end
