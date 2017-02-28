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

  before_validation :extract_fingerprint
  after_create :synchronize_keychain
  after_create :notify_user
  after_destroy :synchronize_keychain

  def key=(value)
    value.strip! unless value.blank?
    write_attribute(:key, value)
  end

  def emails
    @emails ||= Gitlab::Gpg.emails_from_key(key)
  end

  def emails_in_keychain
    @emails_in_keychain ||= Gitlab::Gpg::CurrentKeyChain.emails(fingerprint)
  end

  def emails_with_verified_status
    emails.map do |email|
      [
        email,
        email == user.email && emails_in_keychain.include?(email)
      ]
    end
  end

  def synchronize_keychain
    if emails.include?(user.email)
      add_to_keychain
    else
      remove_from_keychain
    end

    @emails_in_keychain = nil
  end

  private

  def extract_fingerprint
    # we can assume that the result only contains one item as the validation
    # only allows one key
    self.fingerprint = Gitlab::Gpg.fingerprints_from_key(key).first
  end

  def add_to_keychain
    Gitlab::Gpg::CurrentKeyChain.add(key)
  end

  def remove_from_keychain
    Gitlab::Gpg::CurrentKeyChain.remove(fingerprint)
  end

  def notify_user
    run_after_commit { NotificationService.new.new_gpg_key(self) }
  end
end
