require 'digest/md5'

class Key < ActiveRecord::Base
  include AfterCommitQueue
  include Gitlab::CurrentSettings
  include Sortable

  LAST_USED_AT_REFRESH_TIME = 1.day.to_i

  belongs_to :user

  before_validation :generate_fingerprint

  validates :title,
    presence: true,
    length: { maximum: 255 }

  validates :key,
    presence: true,
    length: { maximum: 5000 },
    format: { with: /\A(ssh|ecdsa)-.*\Z/ }

  validates :fingerprint,
    uniqueness: true,
    presence: { message: 'cannot be generated' }

  validate :key_meets_minimum_bit_length, :key_type_is_allowed

  delegate :name, :email, to: :user, prefix: true

  after_commit :add_to_shell, on: :create
  after_commit :notify_user, on: :create
  after_create :post_create_hook
  after_commit :remove_from_shell, on: :destroy
  after_destroy :post_destroy_hook

  def key=(value)
    value&.delete!("\n\r")
    value.strip! unless value.blank?
    write_attribute(:key, value)
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

  def update_last_used_at
    lease = Gitlab::ExclusiveLease.new("key_update_last_used_at:#{id}", timeout: LAST_USED_AT_REFRESH_TIME)
    return unless lease.try_obtain

    UseKeyWorker.perform_async(id)
  end

  def add_to_shell
    GitlabShellWorker.perform_async(
      :add_key,
      shell_id,
      key
    )
  end

  def post_create_hook
    SystemHooksService.new.execute_hooks_for(self, :create)
  end

  def remove_from_shell
    GitlabShellWorker.perform_async(
      :remove_key,
      shell_id,
      key
    )
  end

  def post_destroy_hook
    SystemHooksService.new.execute_hooks_for(self, :destroy)
  end

  def public_key
    @public_key ||= Gitlab::SSHPublicKey.new(key)
  end

  private

  def generate_fingerprint
    self.fingerprint = nil

    return unless self.key.present?

    self.fingerprint = public_key.fingerprint
  end

  def key_meets_minimum_bit_length
    case public_key.type
    when :rsa
      if public_key.bits < current_application_settings.minimum_rsa_bits
        errors.add(:key, "length must be at least #{current_application_settings.minimum_rsa_bits} bits")
      end
    when :dsa
      if public_key.bits < current_application_settings.minimum_dsa_bits
        errors.add(:key, "length must be at least #{current_application_settings.minimum_dsa_bits} bits")
      end
    when :ecdsa
      if public_key.bits < current_application_settings.minimum_ecdsa_bits
        errors.add(:key, "elliptic curve size must be at least #{current_application_settings.minimum_ecdsa_bits} bits")
      end
    when :ed25519
      if public_key.bits < current_application_settings.minimum_ed25519_bits
        errors.add(:key, "length must be at least #{current_application_settings.minimum_ed25519_bits} bits")
      end
    end
  end

  def key_type_is_allowed
    unless current_application_settings.allowed_key_types.include?(public_key.type.to_s)
      allowed_types =
        current_application_settings
        .allowed_key_types
        .map(&:upcase)
        .to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')

      errors.add(:key, "type is not allowed. Must be #{allowed_types}")
    end
  end

  def notify_user
    NotificationService.new.new_key(self)
  end
end
