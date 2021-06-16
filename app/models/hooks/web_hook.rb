# frozen_string_literal: true

class WebHook < ApplicationRecord
  include Sortable

  MAX_FAILURES = 100
  FAILURE_THRESHOLD = 3 # three strikes
  INITIAL_BACKOFF = 10.minutes
  MAX_BACKOFF = 1.day
  BACKOFF_GROWTH_FACTOR = 2.0

  attr_encrypted :token,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_32

  attr_encrypted :url,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_32

  has_many :web_hook_logs

  validates :url, presence: true
  validates :url, public_url: true, unless: ->(hook) { hook.is_a?(SystemHook) }

  validates :token, format: { without: /\n/ }
  validates :push_events_branch_filter, branch_filter: true

  scope :executable, -> do
    next all unless Feature.enabled?(:web_hooks_disable_failed)

    where('recent_failures <= ? AND (disabled_until IS NULL OR disabled_until < ?)', FAILURE_THRESHOLD, Time.current)
  end

  def executable?
    return true unless web_hooks_disable_failed?

    recent_failures <= FAILURE_THRESHOLD && (disabled_until.nil? || disabled_until < Time.current)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def execute(data, hook_name)
    WebHookService.new(self, data, hook_name).execute if executable?
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def async_execute(data, hook_name)
    WebHookService.new(self, data, hook_name).async_execute if executable?
  end
  # rubocop: enable CodeReuse/ServiceClass

  # Allow urls pointing localhost and the local network
  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
  end

  def help_path
    'user/project/integrations/webhooks'
  end

  def next_backoff
    return MAX_BACKOFF if backoff_count >= 8 # optimization to prevent expensive exponentiation and possible overflows

    (INITIAL_BACKOFF * (BACKOFF_GROWTH_FACTOR**backoff_count))
      .clamp(INITIAL_BACKOFF, MAX_BACKOFF)
      .seconds
  end

  def disable!
    update!(recent_failures: FAILURE_THRESHOLD + 1)
  end

  def enable!
    return if recent_failures == 0 && disabled_until.nil? && backoff_count == 0

    update!(recent_failures: 0, disabled_until: nil, backoff_count: 0)
  end

  def backoff!
    update!(disabled_until: next_backoff.from_now, backoff_count: backoff_count.succ.clamp(0, MAX_FAILURES))
  end

  def failed!
    update!(recent_failures: recent_failures + 1) if recent_failures < MAX_FAILURES
  end

  # Overridden in ProjectHook and GroupHook, other webhooks are not rate-limited.
  def rate_limit
    nil
  end

  # Custom attributes to be included in the worker context.
  def application_context
    { related_class: type }
  end

  private

  def web_hooks_disable_failed?
    Feature.enabled?(:web_hooks_disable_failed)
  end
end
