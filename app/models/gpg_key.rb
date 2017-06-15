class GpgKey < ActiveRecord::Base
  include AfterCommitQueue

  KEY_PREFIX = '-----BEGIN PGP PUBLIC KEY BLOCK-----'.freeze

  belongs_to :user

  validates :key,
    presence: true,
    uniqueness: true,
    format: {
      with: /\A#{KEY_PREFIX}((?!#{KEY_PREFIX}).)+\Z/m,
      message: "is invalid. A valid public GPG key begins with '#{KEY_PREFIX}'"
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
  after_create :update_invalid_gpg_signatures
  after_create :notify_user

  def key=(value)
    value.strip! unless value.blank?
    write_attribute(:key, value)
  end

  def emails
    @emails ||= Gitlab::Gpg.emails_from_key(key)
  end

  def emails_with_verified_status
    emails.map do |email|
      [
        email,
        email == user.email
      ]
    end
  end

  def verified?
    emails_with_verified_status.any? { |_email, verified| verified }
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

  def update_invalid_gpg_signatures
    run_after_commit { Gitlab::Gpg::InvalidGpgSignatureUpdater.new(self).run }
  end

  def notify_user
    run_after_commit { NotificationService.new.new_gpg_key(self) }
  end
end
