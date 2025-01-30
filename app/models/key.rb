# frozen_string_literal: true

class Key < ApplicationRecord
  include AfterCommitQueue
  include Sortable
  include ShaAttribute
  include Expirable
  include FromUnion
  include Todoable
  include CreatedAtFilterable

  sha256_attribute :fingerprint_sha256

  belongs_to :user

  has_many :ssh_signatures, class_name: 'CommitSignatures::SshSignature'

  has_many :todos, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent -- Polymorphic association

  before_validation :generate_fingerprint

  validates :title,
    presence: true,
    length: { maximum: 255 }

  validates :key,
    presence: true,
    ssh_key: true,
    length: { maximum: 5000 },
    format: { with: /\A(#{Gitlab::SSHPublicKey.supported_algorithms.join('|')})/ }

  validates :fingerprint_sha256,
    uniqueness: true,
    presence: { message: 'cannot be generated' }

  validate :expiration, on: :create
  validate :banned_key, if: :key_changed?

  delegate :name, :email, to: :user, prefix: true

  enum usage_type: {
    auth_and_signing: 0,
    auth: 1,
    signing: 2
  }

  after_create :post_create_hook
  after_create :refresh_user_cache
  after_destroy :post_destroy_hook
  after_destroy :refresh_user_cache
  after_commit :add_to_authorized_keys, on: :create
  after_commit :remove_from_authorized_keys, on: :destroy

  alias_attribute :fingerprint_md5, :fingerprint
  alias_attribute :name, :title

  scope :preload_users, -> { preload(:user) }
  scope :for_user, ->(user) { where(user: user) }
  scope :order_last_used_at_desc, -> { reorder(arel_table[:last_used_at].desc.nulls_last) }
  scope :auth, -> { where(usage_type: [:auth, :auth_and_signing]) }
  scope :signing, -> { where(usage_type: [:signing, :auth_and_signing]) }

  # Date is set specifically in this scope to improve query time.
  scope :expired_today_and_not_notified, -> { where(["date(expires_at AT TIME ZONE 'UTC') = CURRENT_DATE AND expiry_notification_delivered_at IS NULL"]) }
  scope :expiring_soon_and_not_notified, -> { where(["date(expires_at AT TIME ZONE 'UTC') > CURRENT_DATE AND date(expires_at AT TIME ZONE 'UTC') < ? AND before_expiry_notification_delivered_at IS NULL", DAYS_TO_EXPIRE.days.from_now.to_date]) }

  scope :expires_before, ->(date) { where(arel_table[:expires_at].lteq(date)) }
  scope :expires_after, ->(date) { where(arel_table[:expires_at].gteq(date)) }

  def self.regular_keys
    where(type: ['Key', nil])
  end

  def key=(value)
    write_attribute(:key, value.present? ? Gitlab::SSHPublicKey.sanitize(value) : nil)

    @public_key = nil
  end

  def publishable_key
    # Strip out the keys comment so we don't leak email addresses
    # Replace with simple ident of user_name (hostname)
    self.key.split[0..1].push("#{self.user_name} (#{Gitlab.config.gitlab.host})").join(' ')
  end

  # projects that has this key
  def projects
    user.authorized_projects
  end

  def shell_id
    "key-#{id}"
  end

  # EE overrides this
  def can_delete?
    true
  end

  # rubocop: disable CodeReuse/ServiceClass
  def update_last_used_at
    Keys::LastUsedService.new(self).execute_async
  end
  # rubocop: enable CodeReuse/ServiceClass

  def add_to_authorized_keys
    return unless Gitlab::CurrentSettings.authorized_keys_enabled?

    AuthorizedKeysWorker.perform_async('add_key', shell_id, key)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def post_create_hook
    SystemHooksService.new.execute_hooks_for(self, :create)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def remove_from_authorized_keys
    return unless Gitlab::CurrentSettings.authorized_keys_enabled?

    AuthorizedKeysWorker.perform_async('remove_key', shell_id)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def refresh_user_cache
    return unless user

    Users::KeysCountService.new(user).refresh_cache
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def post_destroy_hook
    SystemHooksService.new.execute_hooks_for(self, :destroy)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def public_key
    @public_key ||= Gitlab::SSHPublicKey.new(key)
  end

  def ensure_sha256_fingerprint!
    return if self.fingerprint_sha256

    save if generate_fingerprint
  end

  def signing?
    super || auth_and_signing?
  end

  def readable_by?(user)
    user_id == user.id
  end

  def to_reference
    fingerprint
  end

  private

  def generate_fingerprint
    self.fingerprint = nil
    self.fingerprint_sha256 = nil

    return unless public_key.valid?

    self.fingerprint_md5 = public_key.fingerprint unless Gitlab::FIPS.enabled?
    self.fingerprint_sha256 = public_key.fingerprint_sha256.gsub("SHA256:", "")
  end

  def banned_key
    return unless public_key.banned?

    help_page_url = Rails.application.routes.url_helpers.help_page_url(
      'security/ssh_keys_restrictions.md',
      anchor: 'block-banned-or-compromised-keys'
    )

    errors.add(
      :key,
      _('cannot be used because it belongs to a compromised private key. Stop using this key and generate a new one.'),
      help_page_url: help_page_url
    )
  end

  def expiration
    errors.add(:key, message: 'has expired') if expired?
  end
end

Key.prepend_mod_with('Key')
