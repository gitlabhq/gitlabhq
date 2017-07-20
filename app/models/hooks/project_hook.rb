class ProjectHook < WebHook
  include CustomModelNaming

  self.singular_route_key = :hook

  TRIGGERS = {
    push_hooks:               :push_events,
    tag_push_hooks:           :tag_push_events,
    issue_hooks:              :issues_events,
    confidential_issue_hooks: :confidential_issues_events,
    note_hooks:               :note_events,
    merge_request_hooks:      :merge_requests_events,
    job_hooks:                :job_events,
    pipeline_hooks:           :pipeline_events,
    wiki_page_hooks:          :wiki_page_events
  }.freeze

  TRIGGERS.each do |trigger, event|
    scope trigger, -> { where(event => true) }
  end

  belongs_to :project
  validates :project, presence: true
end
