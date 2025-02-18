# frozen_string_literal: true

# This model is being migrated to the NoStiSystemHook model temporarily.
# Please ensure all changes here are reflected in the new model.
# More info here: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175729
class SystemHook < WebHook
  extend ::Gitlab::Utils::Override
  include TriggerableHooks

  self.allow_legacy_sti_class = true

  has_many :web_hook_logs, foreign_key: 'web_hook_id', inverse_of: :web_hook

  triggerable_hooks [
    :repository_update_hooks,
    :push_hooks,
    :tag_push_hooks,
    :merge_request_hooks
  ]

  attribute :push_events, default: false
  attribute :repository_update_events, default: true
  attribute :merge_requests_events, default: false

  validates :url, system_hook_url: true, unless: ->(hook) { hook.url_variables? }

  # Allow urls pointing localhost and the local network
  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_system_hooks?
  end

  def pluralized_name
    s_('Webhooks|System hooks')
  end

  def help_path
    'administration/system_hooks'
  end

  override :validate_public_url?
  def validate_public_url?
    false
  end
end
