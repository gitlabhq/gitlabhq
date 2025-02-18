# frozen_string_literal: true

class ProjectHook < WebHook
  include TriggerableHooks
  include Presentable
  include Limitable
  extend ::Gitlab::Utils::Override

  AVAILABLE_HOOKS = [
    :confidential_issue_hooks,
    :confidential_note_hooks,
    :deployment_hooks,
    :emoji_hooks,
    :feature_flag_hooks,
    :issue_hooks,
    :job_hooks,
    :merge_request_hooks,
    :note_hooks,
    :pipeline_hooks,
    :push_hooks,
    :release_hooks,
    :resource_access_token_hooks,
    :tag_push_hooks,
    :wiki_page_hooks
  ].freeze

  self.allow_legacy_sti_class = true

  self.limit_scope = :project

  has_many :web_hook_logs, foreign_key: 'web_hook_id', inverse_of: :web_hook

  belongs_to :project
  validates :project, presence: true

  scope :for_projects, ->(project) { where(project: project) }

  def self.available_hooks
    AVAILABLE_HOOKS
  end

  triggerable_hooks available_hooks

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
