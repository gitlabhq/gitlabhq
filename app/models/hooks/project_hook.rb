# frozen_string_literal: true

class ProjectHook < WebHook
  include TriggerableHooks
  include Presentable
  include Limitable
  extend ::Gitlab::Utils::Override

  self.allow_legacy_sti_class = true

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
    :wiki_page_hooks,
    :deployment_hooks,
    :feature_flag_hooks,
    :release_hooks,
    :emoji_hooks,
    :resource_access_token_hooks
  ]

  belongs_to :project
  validates :project, presence: true

  scope :for_projects, ->(project) { where(project: project) }

  def pluralized_name
    _('Webhooks')
  end

  override :application_context
  def application_context
    super.merge(project: project)
  end

  override :parent
  def parent
    project
  end
end

ProjectHook.prepend_mod_with('ProjectHook')
