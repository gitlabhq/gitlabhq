class GpgKey < ActiveRecord::Base
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
  after_create :add_to_keychain
  after_destroy :remove_from_keychain

  def key=(value)
    value.strip! unless value.blank?
    write_attribute(:key, value)
  end

  def emails
    Gitlab::Gpg::CurrentKeyChain.emails(fingerprint)
  end

  private

  def extract_fingerprint
    # we can assume that the result only contains one item as the validation
    # only allows one key
    self.fingerprint = Gitlab::Gpg.fingerprints_from_key(key).first
  end

  def add_to_keychain
    Gitlab::Gpg.add_to_keychain(key)
  end

  def remove_from_keychain
    Gitlab::Gpg.remove_from_keychain(fingerprint)
  end
end
