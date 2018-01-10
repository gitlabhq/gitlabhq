class GroupHook < ProjectHook
  include CustomModelNaming
  include TriggerableHooks

  self.singular_route_key = :hook

  triggerable_hooks [
    :push_hooks,
    :tag_push_hooks,
    :issue_hooks,
    :confidential_issue_hooks,
    :note_hooks,
    :merge_request_hooks,
    :job_hooks,
    :pipeline_hooks,
    :wiki_page_hooks
  ]

  belongs_to :group

  clear_validators!
  validates :url, presence: true, url: true
end
