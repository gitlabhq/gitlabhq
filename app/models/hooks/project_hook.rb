class ProjectHook < WebHook
  include CustomModelNaming

  self.singular_route_key = :hook

  belongs_to :project

  scope :issue_hooks, -> { where(issues_events: true) }
  scope :confidential_issue_hooks, -> { where(confidential_issues_events: true) }
  scope :note_hooks, -> { where(note_events: true) }
  scope :merge_request_hooks, -> { where(merge_requests_events: true) }
  scope :build_hooks, -> { where(build_events: true) }
  scope :pipeline_hooks, -> { where(pipeline_events: true) }
  scope :wiki_page_hooks, ->  { where(wiki_page_events: true) }
end
