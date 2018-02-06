require 'digest/md5'

class Key < ActiveRecord::Base
  include AfterCommitQueue
  include Sortable

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

  validate :key_meets_restrictions

  delegate :name, :email, to: :user, prefix: true

  after_commit :add_to_shell, on: :create
  after_create :post_create_hook
  after_create :refresh_user_cache
  after_commit :remove_from_shell, on: :destroy
  after_destroy :post_destroy_hook
  after_destroy :refresh_user_cache

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

  def update_last_used_at
    Keys::LastUsedService.new(self).execute
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

  def refresh_user_cache
    return unless user

    Users::KeysCountService.new(user).refresh_cache
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

    return unless public_key.valid?

    self.fingerprint = public_key.fingerprint
  end

  def key_meets_restrictions
    restriction = Gitlab::CurrentSettings.key_restriction_for(public_key.type)

    if restriction == ApplicationSetting::FORBIDDEN_KEY_VALUE
      errors.add(:key, forbidden_key_type_message)
    elsif public_key.bits < restriction
      errors.add(:key, "must be at least #{restriction} bits")
    end
  end

  def forbidden_key_type_message
    allowed_types =
      Gitlab::CurrentSettings
        .allowed_key_types
        .map(&:upcase)
        .to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')

    "type is forbidden. Must be #{allowed_types}"
  end
end
