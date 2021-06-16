# frozen_string_literal: true

class RemoteMirror < ApplicationRecord
  include AfterCommitQueue
  include MirrorAuthentication
  include SafeUrl

  MAX_FIRST_RUNTIME = 3.hours
  MAX_INCREMENTAL_RUNTIME = 1.hour
  PROTECTED_BACKOFF_DELAY   = 1.minute
  UNPROTECTED_BACKOFF_DELAY = 5.minutes

  attr_encrypted :credentials,
                 key: Settings.attr_encrypted_db_key_base,
                 marshal: true,
                 encode: true,
                 mode: :per_attribute_iv_and_salt,
                 insecure_mode: true,
                 algorithm: 'aes-256-cbc'

  belongs_to :project, inverse_of: :remote_mirrors

  validates :url, presence: true, public_url: { schemes: %w(ssh git http https), allow_blank: true, enforce_user: true }

  before_save :set_new_remote_name, if: :mirror_url_changed?

  after_save :set_override_remote_mirror_available, unless: -> { Gitlab::CurrentSettings.current_application_settings.mirror_available }
  after_save :refresh_remote, if: :saved_change_to_mirror_url?
  after_update :reset_fields, if: :saved_change_to_mirror_url?

  after_commit :remove_remote, on: :destroy

  before_validation :store_credentials

  scope :enabled, -> { where(enabled: true) }
  scope :started, -> { with_update_status(:started) }

  scope :stuck, -> do
    started
      .where('(last_update_started_at < ? AND last_update_at IS NOT NULL)',
             MAX_INCREMENTAL_RUNTIME.ago)
      .or(where('(last_update_started_at < ? AND last_update_at IS NULL)',
                MAX_FIRST_RUNTIME.ago))
  end

  state_machine :update_status, initial: :none do
    event :update_start do
      transition any => :started
    end

    event :update_finish do
      transition started: :finished
    end

    event :update_fail do
      transition started: :failed
    end

    event :update_retry do
      transition started: :to_retry
    end

    state :started
    state :finished
    state :failed
    state :to_retry

    after_transition any => :started do |remote_mirror, _|
      Gitlab::Metrics.add_event(:remote_mirrors_running)

      remote_mirror.update(last_update_started_at: Time.current)
    end

    after_transition started: :finished do |remote_mirror, _|
      Gitlab::Metrics.add_event(:remote_mirrors_finished)

      timestamp = Time.current
      remote_mirror.update!(
        last_update_at: timestamp,
        last_successful_update_at: timestamp,
        last_error: nil,
        error_notification_sent: false
      )
    end

    after_transition started: :failed do |remote_mirror|
      remote_mirror.send_failure_notifications
    end
  end

  def remote_name
    super || fallback_remote_name
  end

  def update_failed?
    update_status == 'failed'
  end

  def update_in_progress?
    update_status == 'started'
  end

  def update_repository(inmemory_remote:)
    Gitlab::Git::RemoteMirror.new(
      project.repository.raw,
      remote_name,
      inmemory_remote ? remote_url : nil,
      **options_for_update
    ).update
  end

  def options_for_update
    options = {
      keep_divergent_refs: keep_divergent_refs?
    }

    if only_protected_branches?
      options[:only_branches_matching] = project.protected_branches.pluck(:name)
    end

    if ssh_mirror_url?
      if ssh_key_auth? && ssh_private_key.present?
        options[:ssh_key] = ssh_private_key
      end

      if ssh_known_hosts.present?
        options[:known_hosts] = ssh_known_hosts
      end
    end

    options
  end

  def sync?
    enabled?
  end

  def sync
    return unless sync?

    if recently_scheduled?
      RepositoryUpdateRemoteMirrorWorker.perform_in(backoff_delay, self.id, Time.current)
    else
      RepositoryUpdateRemoteMirrorWorker.perform_async(self.id, Time.current)
    end
  end

  def enabled
    return false unless project && super
    return false unless project.remote_mirror_available?
    return false unless project.repository_exists?
    return false if project.pending_delete?

    true
  end
  alias_method :enabled?, :enabled

  def disabled?
    !enabled?
  end

  def updated_since?(timestamp)
    return false if failed?

    last_update_started_at && last_update_started_at > timestamp
  end

  def mark_for_delete_if_blank_url
    mark_for_destruction if url.blank?
  end

  def update_error_message(error_message)
    self.last_error = Gitlab::UrlSanitizer.sanitize(error_message)
  end

  def mark_for_retry!(error_message)
    update_error_message(error_message)
    update_retry!
  end

  def mark_as_failed!(error_message)
    update_error_message(error_message)
    update_fail!
  end

  # Force the mrror into the retry state
  def hard_retry!(error_message)
    update_error_message(error_message)
    self.update_status = :to_retry

    save!(validate: false)
  end

  # Force the mirror into the failed state
  def hard_fail!(error_message)
    update_error_message(error_message)
    self.update_status = :failed

    save!(validate: false)

    send_failure_notifications
  end

  def url=(value)
    super(value) && return unless Gitlab::UrlSanitizer.valid?(value)

    mirror_url = Gitlab::UrlSanitizer.new(value)
    self.credentials ||= {}
    self.credentials = self.credentials.merge(mirror_url.credentials)

    super(mirror_url.sanitized_url)
  end

  def url
    if super
      Gitlab::UrlSanitizer.new(super, credentials: credentials).full_url
    end
  rescue StandardError
    super
  end

  def safe_url
    super(allowed_usernames: %w[git])
  end

  def bare_url
    Gitlab::UrlSanitizer.new(read_attribute(:url)).full_url
  end

  def ensure_remote!
    return unless project
    return unless remote_name && remote_url

    # If this fails or the remote already exists, we won't know due to
    # https://gitlab.com/gitlab-org/gitaly/issues/1317
    project.repository.add_remote(remote_name, remote_url)
  end

  def after_sent_notification
    update_column(:error_notification_sent, true)
  end

  def backoff_delay
    if self.only_protected_branches
      PROTECTED_BACKOFF_DELAY
    else
      UNPROTECTED_BACKOFF_DELAY
    end
  end

  def max_runtime
    last_update_at.present? ? MAX_INCREMENTAL_RUNTIME : MAX_FIRST_RUNTIME
  end

  def send_failure_notifications
    Gitlab::Metrics.add_event(:remote_mirrors_failed)

    run_after_commit do
      RemoteMirrorNotificationWorker.perform_async(id)
    end

    self.last_update_at = Time.current
    save!(validate: false)
  end

  private

  def store_credentials
    # This is a necessary workaround for attr_encrypted, which doesn't otherwise
    # notice that the credentials have changed
    self.credentials = self.credentials
  end

  # The remote URL omits any password if SSH public-key authentication is in use
  def remote_url
    return url unless ssh_key_auth? && password.present?

    Gitlab::UrlSanitizer.new(read_attribute(:url), credentials: { user: user }).full_url
  rescue StandardError
    super
  end

  def fallback_remote_name
    return unless id

    "remote_mirror_#{id}"
  end

  def recently_scheduled?
    return false unless self.last_update_started_at

    self.last_update_started_at >= Time.current - backoff_delay
  end

  def reset_fields
    update_columns(
      last_error: nil,
      last_update_at: nil,
      last_successful_update_at: nil,
      update_status: 'finished',
      error_notification_sent: false
    )
  end

  def set_override_remote_mirror_available
    enabled = read_attribute(:enabled)

    project.update(remote_mirror_available_overridden: enabled)
  end

  def set_new_remote_name
    self.remote_name = "remote_mirror_#{SecureRandom.hex}"
  end

  def refresh_remote
    return unless project

    # Before adding a new remote we have to delete the data from
    # the previous remote name
    prev_remote_name = remote_name_before_last_save || fallback_remote_name
    run_after_commit do
      project.repository.async_remove_remote(prev_remote_name)
    end

    project.repository.add_remote(remote_name, remote_url)
  end

  def remove_remote
    return unless project # could be pending to delete so don't need to touch the git repository

    project.repository.async_remove_remote(remote_name)
  end

  def mirror_url_changed?
    url_changed? || attribute_changed?(:credentials)
  end

  def saved_change_to_mirror_url?
    saved_change_to_url? || saved_change_to_credentials?
  end
end

RemoteMirror.prepend_mod_with('RemoteMirror')
