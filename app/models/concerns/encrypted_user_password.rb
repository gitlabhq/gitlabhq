# frozen_string_literal: true

# Support for both BCrypt and PBKDF2+SHA512 user passwords
# Meant to be used exclusively with User model but extracted
# to a concern for isolation and clarity.
module EncryptedUserPassword
  extend ActiveSupport::Concern

  BCRYPT_PREFIX = '$2a$'
  PBKDF2_SHA512_PREFIX = '$pbkdf2-sha512$'
  PBKDF2_SALT_LENGTH = 64

  BCRYPT_STRATEGY = :bcrypt
  PBKDF2_SHA512_STRATEGY = :pbkdf2_sha512

  class_methods do
    def stretches
      prior_stretches = Rails.env.test? ? 1 : 10

      return prior_stretches unless Feature.enabled?(:increase_password_storage_stretches) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- required to enable FFing a Class method, which is required to FF the Stretches config

      Rails.env.test? ? 5 : 13
    end
  end

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
                                  Devise.friendly_token(PBKDF2_SALT_LENGTH))
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
    # A note on ordering here:
    # Other code expects to use this function to switch between pbkdf2 and bcrypt.
    # Hence, if password strategy != encryptor, we need to fail immediately and migrate.
    # Reversing this ordering will break tests in spec/models/concerns/encrypted_user_password_spec.rb.

    if password_strategy == encryptor
      if BCRYPT_STRATEGY == password_strategy
        return true if Feature.disabled?(:increase_password_storage_stretches) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- required to enable FFing a Class method, which is required to FF the Stretches config
        return true if bcrypt_password_matches_current_stretches?
      elsif PBKDF2_SHA512_STRATEGY == password_strategy
        return true if pbkdf2_password_matches_salt_length?
      end
    end

    # We do not want to send a "your password changed" notification on stretch update
    skip_password_change_notification!
    update_attribute(:password, password)
  end

  def bcrypt_password_matches_current_stretches?
    return false unless bcrypt_password?

    ::BCrypt::Password.new(encrypted_password).cost == self.class.stretches
  end

  def pbkdf2_password_matches_salt_length?
    return false unless pbkdf2_password?

    current_salt_length = Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512
      .split_digest(encrypted_password)[:salt].length

    PBKDF2_SALT_LENGTH == current_salt_length
  end

  def encryptor
    return BCRYPT_STRATEGY unless Gitlab::FIPS.enabled?

    PBKDF2_SHA512_STRATEGY
  end
end
