# frozen_string_literal: true

class ProjectHook < WebHook
  include TriggerableHooks
  include Presentable
  include Limitable

  self.limit_scope = :project

  triggerable_hooks [
    :push_hooks,
    :tag_push_hooks,
    :issue_hooks,
    :confidential_issue_hooks,
    :note_hooks,
    :confidential_note_hooks,
    :merge_request_hooks,
    :job_hooks,
    :pipeline_hooks,
    :wiki_page_hooks
  ]

  belongs_to :project
  validates :project, presence: true

  def pluralized_name
    _('Webhooks')
  end
end

ProjectHook.prepend_if_ee('EE::ProjectHook')
