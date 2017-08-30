class RemoteMirror < ActiveRecord::Base
  include AfterCommitQueue

  BACKOFF_DELAY = 5.minutes

  attr_encrypted :credentials,
                 key: Gitlab::Application.secrets.db_key_base,
                 marshal: true,
                 encode: true,
                 mode: :per_attribute_iv_and_salt,
                 insecure_mode: true,
                 algorithm: 'aes-256-cbc'

  belongs_to :project, inverse_of: :remote_mirrors

  validates :url, presence: true, url: { protocols: %w(ssh git http https), allow_blank: true }

  validate  :url_availability, if: -> (mirror) { mirror.url_changed? || mirror.enabled? }

  after_save :refresh_remote, if: :mirror_url_changed?
  after_update :reset_fields, if: :mirror_url_changed?
  after_destroy :remove_remote

  scope :enabled, -> { where(enabled: true) }
  scope :started, -> { with_update_status(:started) }
  scope :stuck,   -> { started.where('last_update_at < ? OR (last_update_at IS NULL AND updated_at < ?)', 1.day.ago, 1.day.ago) }

  state_machine :update_status, initial: :none do
    event :update_start do
      transition [:none, :finished, :failed] => :started
    end

    event :update_finish do
      transition started: :finished
    end

    event :update_fail do
      transition started: :failed
    end

    state :started
    state :finished
    state :failed

    after_transition any => :started do |remote_mirror, _|
      Gitlab::Metrics.add_event(:remote_mirrors_running, path: remote_mirror.project.full_path)

      remote_mirror.update(last_update_started_at: Time.now)
    end

    after_transition started: :finished do |remote_mirror, _|
      Gitlab::Metrics.add_event(:remote_mirrors_finished, path: remote_mirror.project.full_path)

      timestamp = Time.now
      remote_mirror.update_attributes!(
        last_update_at: timestamp, last_successful_update_at: timestamp, last_error: nil
      )
    end

    after_transition started: :failed do |remote_mirror, _|
      Gitlab::Metrics.add_event(:remote_mirrors_failed, path: remote_mirror.project.full_path)

      remote_mirror.update(last_update_at: Time.now)
    end
  end

  def ref_name
    "remote_mirror_#{id}"
  end

  def update_failed?
    update_status == 'failed'
  end

  def update_in_progress?
    update_status == 'started'
  end

  def sync
    return unless enabled?
    return if Gitlab::Geo.secondary?

    RepositoryUpdateRemoteMirrorWorker.perform_in(BACKOFF_DELAY, self.id, Time.now)
  end

  def enabled
    return false unless project && super
    return false unless project.repository_exists?
    return false if project.pending_delete?

    # Sync is only enabled when the license permits it
    project.feature_available?(:repository_mirrors)
  end
  alias_method :enabled?, :enabled

  def updated_since?(timestamp)
    last_update_started_at && last_update_started_at > timestamp && !update_failed?
  end

  def mark_for_delete_if_blank_url
    mark_for_destruction if url.blank?
  end

  def mark_as_failed(error_message)
    update_fail
    update_column(:last_error, Gitlab::UrlSanitizer.sanitize(error_message))
  end

  def url=(value)
    mirror_url = Gitlab::UrlSanitizer.new(value)
    self.credentials = mirror_url.credentials

    super(mirror_url.sanitized_url)
  end

  def url
    if super
      Gitlab::UrlSanitizer.new(super, credentials: credentials).full_url
    end
  end

  def safe_url
    return if url.nil?

    result = URI.parse(url)
    result.password = '*****' if result.password
    result.user = '*****' if result.user && result.user != "git" # tokens or other data may be saved as user
    result.to_s
  end

  private

  def url_availability
    return unless project

    if project.import_url == url && project.mirror?
      errors.add(:url, 'is already in use')
    end
  end

  def reset_fields
    update_columns(
      last_error: nil,
      last_update_at: nil,
      last_successful_update_at: nil,
      update_status: 'finished'
    )
  end

  def refresh_remote
    return unless project

    project.repository.remove_remote(ref_name)
    project.repository.add_remote(ref_name, url)
  end

  def remove_remote
    if project # could be pending to delete so don't need to touch the git repository
      project.repository.remove_remote(ref_name)
    end
  end

  def mirror_url_changed?
    url_changed? || encrypted_credentials_changed?
  end
end
