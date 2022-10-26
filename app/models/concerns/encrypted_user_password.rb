# frozen_string_literal: true

# Support for both BCrypt and PBKDF2+SHA512 user passwords
# Meant to be used exclusively with User model but extracted
# to a concern for isolation and clarity.
module EncryptedUserPassword
  extend ActiveSupport::Concern

  BCRYPT_PREFIX = '$2a$'
  PBKDF2_SHA512_PREFIX = '$pbkdf2-sha512$'

  BCRYPT_STRATEGY = :bcrypt
  PBKDF2_SHA512_STRATEGY = :pbkdf2_sha512

  # Use Devise DatabaseAuthenticatable#authenticatable_salt
  # unless encrypted password is PBKDF2+SHA512.
  def authenticatable_salt
    return super unless pbkdf2_password?

    Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.split_digest(encrypted_password)[:salt]
  end

  # Called by Devise during database authentication.
  # Also migrates the user password to the configured
  # encryption type (BCrypt or PBKDF2+SHA512), if needed.
  def valid_password?(password)
    return false unless password_matches?(password)

    migrate_password!(password)
  end

  def password=(new_password)
    @password = new_password # rubocop:disable Gitlab/ModuleWithInstanceVariables
    return unless new_password.present?

    self.encrypted_password = if Gitlab::FIPS.enabled?
                                Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.digest(
                                  new_password,
                                  Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512::STRETCHES,
                                  Devise.friendly_token[0, 16])
                              else
                                Devise::Encryptor.digest(self.class, new_password)
                              end
  end

  private

  def password_strategy
    return BCRYPT_STRATEGY if encrypted_password.starts_with?(BCRYPT_PREFIX)
    return PBKDF2_SHA512_STRATEGY if encrypted_password.starts_with?(PBKDF2_SHA512_PREFIX)

    :unknown
  end

  def pbkdf2_password?
    password_strategy == PBKDF2_SHA512_STRATEGY
  end

  def bcrypt_password?
    password_strategy == BCRYPT_STRATEGY
  end

  def password_matches?(password)
    if bcrypt_password?
      Devise::Encryptor.compare(self.class, encrypted_password, password)
    elsif pbkdf2_password?
      Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.compare(encrypted_password, password)
    end
  end

  def migrate_password!(password)
    return true if password_strategy == encryptor

    update_attribute(:password, password)
  end

  def encryptor
    return BCRYPT_STRATEGY unless Gitlab::FIPS.enabled?

    PBKDF2_SHA512_STRATEGY
  end
end
