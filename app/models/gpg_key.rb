class GpgKey < ActiveRecord::Base
  KEY_PREFIX = '-----BEGIN PGP PUBLIC KEY BLOCK-----'.freeze
  KEY_SUFFIX = '-----END PGP PUBLIC KEY BLOCK-----'.freeze

  include ShaAttribute

  sha_attribute :primary_keyid
  sha_attribute :fingerprint

  belongs_to :user
  has_many :gpg_signatures

  validates :user, presence: true

  validates :key,
    presence: true,
    uniqueness: true,
    format: {
      with: /\A#{KEY_PREFIX}((?!#{KEY_PREFIX})(?!#{KEY_SUFFIX}).)+#{KEY_SUFFIX}\Z/m,
      message: "is invalid. A valid public GPG key begins with '#{KEY_PREFIX}' and ends with '#{KEY_SUFFIX}'"
    }

  validates :fingerprint,
    presence: true,
    uniqueness: true,
    # only validate when the `key` is valid, as we don't want the user to show
    # the error about the fingerprint
    unless: -> { errors.has_key?(:key) }

  validates :primary_keyid,
    presence: true,
    uniqueness: true,
    # only validate when the `key` is valid, as we don't want the user to show
    # the error about the fingerprint
    unless: -> { errors.has_key?(:key) }

  before_validation :extract_fingerprint, :extract_primary_keyid
  after_commit :update_invalid_gpg_signatures, on: :create
  after_commit :notify_user, on: :create

  def primary_keyid
    super&.upcase
  end

  def fingerprint
    super&.upcase
  end

  def key=(value)
    super(value&.strip)
  end

  def user_infos
    @user_infos ||= Gitlab::Gpg.user_infos_from_key(key)
  end

  def verified_user_infos
    user_infos.select do |user_info|
      user.verified_email?(user_info[:email])
    end
  end

  def emails_with_verified_status
    user_infos.map do |user_info|
      [
        user_info[:email],
        user.verified_email?(user_info[:email])
      ]
    end.to_h
  end

  def verified?
    emails_with_verified_status.values.any?
  end

  def verified_and_belongs_to_email?(email)
    emails_with_verified_status.fetch(email, false)
  end

  def update_invalid_gpg_signatures
    InvalidGpgSignatureUpdateWorker.perform_async(self.id)
  end

  def revoke
    GpgSignature
      .where(gpg_key: self)
      .where.not(verification_status: GpgSignature.verification_statuses[:unknown_key])
      .update_all(
        gpg_key_id: nil,
        verification_status: GpgSignature.verification_statuses[:unknown_key],
        updated_at: Time.zone.now
      )

    destroy
  end

  private

  def extract_fingerprint
    # we can assume that the result only contains one item as the validation
    # only allows one key
    self.fingerprint = Gitlab::Gpg.fingerprints_from_key(key).first
  end

  def extract_primary_keyid
    # we can assume that the result only contains one item as the validation
    # only allows one key
    self.primary_keyid = Gitlab::Gpg.primary_keyids_from_key(key).first
  end

  def notify_user
    NotificationService.new.new_gpg_key(self)
  end
end
