class GpgKey < ActiveRecord::Base
  KEY_PREFIX = '-----BEGIN PGP PUBLIC KEY BLOCK-----'.freeze

  belongs_to :user

  validates :fingerprint,
    presence: true,
    uniqueness: true

  validates :key,
    presence: true,
    uniqueness: true,
    format: {
      with: /\A#{KEY_PREFIX}((?!#{KEY_PREFIX}).)+\Z/m
    }

  before_validation :extract_fingerprint

  def key=(value)
    value.strip! unless value.blank?
    write_attribute(:key, value)
  end

  def emails
    raw_key = GPGME::Key.get(fingerprint)
    raw_key.uids.map(&:email)
  end

  private

  def extract_fingerprint
    import = GPGME::Key.import(key)

    return if import.considered == 0

    # we can assume that the result only contains one item as the validation
    # only allows one key
    self.fingerprint = import.imports.first.fingerprint
  end
end
