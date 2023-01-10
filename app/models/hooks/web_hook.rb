# frozen_string_literal: true

class WebHook < ApplicationRecord
  include Sortable

  InterpolationError = Class.new(StandardError)

  MAX_FAILURES = 100
  FAILURE_THRESHOLD = 3 # three strikes
  EXCEEDED_FAILURE_THRESHOLD = FAILURE_THRESHOLD + 1
  INITIAL_BACKOFF = 1.minute
  MAX_BACKOFF = 1.day
  BACKOFF_GROWTH_FACTOR = 2.0
  SECRET_MASK = '************'

  attr_encrypted :token,
                 mode: :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key: Settings.attr_encrypted_db_key_base_32

  attr_encrypted :url,
                 mode: :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key: Settings.attr_encrypted_db_key_base_32

  attr_encrypted :url_variables,
                 mode: :per_attribute_iv,
                 key: Settings.attr_encrypted_db_key_base_32,
                 algorithm: 'aes-256-gcm',
                 marshal: true,
                 marshaler: ::Gitlab::Json,
                 encode: false,
                 encode_iv: false

  has_many :web_hook_logs

  validates :url, presence: true
  validates :url, public_url: true, unless: ->(hook) { hook.is_a?(SystemHook) || hook.url_variables? }

  validates :token, format: { without: /\n/ }
  after_initialize :initialize_url_variables

  before_validation :reset_token
  before_validation :reset_url_variables, unless: ->(hook) { hook.is_a?(ServiceHook) }
  before_validation :set_branch_filter_nil, if: :branch_filter_strategy_all_branches?
  validates :push_events_branch_filter, untrusted_regexp: true, if: :branch_filter_strategy_regex?
  validates :push_events_branch_filter, "web_hooks/wildcard_branch_filter": true, if: :branch_filter_strategy_wildcard?

  validates :url_variables, json_schema: { filename: 'web_hooks_url_variables' }
  validate :no_missing_url_variables
  validates :interpolated_url, public_url: true, if: ->(hook) { hook.url_variables? && hook.errors.empty? }

  enum branch_filter_strategy: {
    wildcard: 0,
    regex: 1,
    all_branches: 2
  }, _prefix: true

  scope :executable, -> do
    where('recent_failures <= ? AND (disabled_until IS NULL OR disabled_until < ?)', FAILURE_THRESHOLD, Time.current)
  end

  # Inverse of executable
  scope :disabled, -> do
    where('recent_failures > ? OR disabled_until >= ?', FAILURE_THRESHOLD, Time.current)
  end

  def executable?
    !temporarily_disabled? && !permanently_disabled?
  end

  def temporarily_disabled?
    return false if recent_failures <= FAILURE_THRESHOLD

    disabled_until.present? && disabled_until >= Time.current
  end

  def permanently_disabled?
    return false if disabled_until.present?

    recent_failures > FAILURE_THRESHOLD
  end

  # rubocop: disable CodeReuse/ServiceClass
  def execute(data, hook_name, force: false)
    # hook.executable? is checked in WebHookService#execute
    WebHookService.new(self, data, hook_name, force: force).execute
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
    return if permanently_disabled?

    update_attribute(:recent_failures, EXCEEDED_FAILURE_THRESHOLD)
  end

  def enable!
    return if recent_failures == 0 && disabled_until.nil? && backoff_count == 0

    assign_attributes(recent_failures: 0, disabled_until: nil, backoff_count: 0)
    save(validate: false)
  end

  # Don't actually back-off until FAILURE_THRESHOLD failures have been seen
  # we mark the grace-period using the recent_failures counter
  def backoff!
    return if permanently_disabled? || (backoff_count >= MAX_FAILURES && temporarily_disabled?)

    attrs = { recent_failures: next_failure_count }

    if recent_failures >= FAILURE_THRESHOLD
      attrs[:backoff_count] = next_backoff_count
      attrs[:disabled_until] = next_backoff.from_now
    end

    assign_attributes(attrs)
    save(validate: false)
  end

  def failed!
    return unless recent_failures < MAX_FAILURES

    assign_attributes(disabled_until: nil, backoff_count: 0, recent_failures: next_failure_count)
    save(validate: false)
  end

  # @return [Boolean] Whether or not the WebHook is currently throttled.
  def rate_limited?
    rate_limiter.rate_limited?
  end

  # @return [Integer] The rate limit for the WebHook. `0` for no limit.
  def rate_limit
    rate_limiter.limit
  end

  # Returns the associated Project or Group for the WebHook if one exists.
  # Overridden by inheriting classes.
  def parent
  end

  # Custom attributes to be included in the worker context.
  def application_context
    { related_class: type }
  end

  def alert_status
    if temporarily_disabled?
      :temporarily_disabled
    elsif permanently_disabled?
      :disabled
    else
      :executable
    end
  end

  # Exclude binary columns by default - they have no sensible JSON encoding
  def serializable_hash(options = nil)
    options = options.try(:dup) || {}
    options[:except] = Array(options[:except]).dup
    options[:except].concat [:encrypted_url_variables, :encrypted_url_variables_iv]

    super(options)
  end

  # See app/validators/json_schemas/web_hooks_url_variables.json
  VARIABLE_REFERENCE_RE = /\{([A-Za-z]+[0-9]*(?:[._-][A-Za-z0-9]+)*)\}/.freeze

  def interpolated_url
    return url unless url.include?('{')

    vars = url_variables
    url.gsub(VARIABLE_REFERENCE_RE) do
      vars.fetch(_1.delete_prefix('{').delete_suffix('}'))
    end
  rescue KeyError => e
    raise InterpolationError, "Invalid URL template. Missing key #{e.key}"
  end

  def update_last_failure
    # Overridden in child classes.
  end

  def masked_token
    token.present? ? SECRET_MASK : nil
  end

  private

  def reset_token
    self.token = nil if url_changed? && !encrypted_token_changed?
  end

  def reset_url_variables
    self.url_variables = {} if url_changed? && !encrypted_url_variables_changed?
  end

  def next_failure_count
    recent_failures.succ.clamp(1, MAX_FAILURES)
  end

  def next_backoff_count
    backoff_count.succ.clamp(1, MAX_FAILURES)
  end

  def initialize_url_variables
    self.url_variables = {} if encrypted_url_variables.nil?
  end

  def rate_limiter
    @rate_limiter ||= Gitlab::WebHooks::RateLimiter.new(self)
  end

  def no_missing_url_variables
    return if url.nil?

    variable_names = url_variables.keys
    used_variables = url.scan(VARIABLE_REFERENCE_RE).map(&:first)

    missing = used_variables - variable_names

    return if missing.empty?

    errors.add(:url, "Invalid URL template. Missing keys: #{missing}")
  end

  def set_branch_filter_nil
    self.push_events_branch_filter = nil
  end
end
