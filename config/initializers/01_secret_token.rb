# frozen_string_literal: true

# WARNING: Before you make a change to secrets.yml, read the development guide for GitLab secrets
# doc/development/application_secrets.md.
#
# This file needs to be loaded BEFORE any initializers that attempt to
# prepend modules that require access to secrets (e.g. EE's 0_as_concern.rb).
#
# Be sure to restart your server when you modify this file.
require 'securerandom'

class SecretsInitializer
  def initialize(secrets_file_path:, rails_env:)
    @secrets_file_path = secrets_file_path
    @rails_env = rails_env
  end

  def secrets_from_file
    @secrets_from_file ||= begin
      YAML.safe_load_file(secrets_file_path)
    rescue Errno::ENOENT
      {}
    end
  end

  def execute!
    set_credentials_from_file_and_env!
    set_missing_from_defaults!
  end

  private

  attr_reader :secrets_file_path, :rails_env

  def secrets_for_env(env)
    secrets = secrets_from_file[env] || {}
    secrets.deep_symbolize_keys
  end

  def set_credentials_from_file_and_env!
    # Inspired by https://github.com/rails/rails/blob/v7.0.8.4/railties/lib/rails/secrets.rb#L25-L36
    # Later, once config/secrets.yml won't be read automatically, we'll need to do it manually, so
    # we anticipate and do it ourselves here.
    secrets = secrets_for_env('shared')
                .merge(secrets_for_env(rails_env))

    # Copy secrets from config/secrets.yml into Rails.application.credentials
    # If we support native Rails.application.credentials later
    # (e.g. config.credentials.yml.enc + config/master.key ), this loop would
    # become a no-op as long as credentials are migrated to config.credentials.yml.enc.
    secrets.each do |key, value|
      next if Rails.application.credentials.public_send(key).present?

      Rails.application.credentials[key] = value
    end

    # Historically, ENV['SECRET_KEY_BASE'] takes precedence over config/secrets.yml, so we maintain that
    # behavior by ensuring the environment variable always overrides the value from config/secrets.yml.
    env_secret_key = ENV['SECRET_KEY_BASE']
    Rails.application.credentials.secret_key_base = env_secret_key if env_secret_key.present?
  end

  def set_missing_from_defaults!
    defaults = {
      secret_key_base: generate_new_secure_token,
      otp_key_base: generate_new_secure_token,
      db_key_base: generate_new_secure_token,
      openid_connect_signing_key: generate_new_rsa_private_key,
      # 1. We set the following two keys as an array to support keys rotation.
      #    The last key in the array is always used to encrypt data:
      #    https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/encryption/key_provider.rb#L21
      #    while all the keys are used (in the order they're defined) to decrypt data:
      #    https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/encryption/cipher.rb#L26.
      #    This allows to rotate keys by adding a new key as the last key, and start a re-encryption process that
      #    runs in the background: https://gitlab.com/gitlab-org/gitlab/-/issues/494976
      # 2. We use the same method and length as Rails' defaults:
      #    https://github.com/rails/rails/blob/v7.0.8.4/activerecord/lib/active_record/railties/databases.rake#L537-L540
      active_record_encryption_primary_key: [generate_new_secure_random_alphanumeric(32)],
      active_record_encryption_deterministic_key: [generate_new_secure_random_alphanumeric(32)],
      active_record_encryption_key_derivation_salt: generate_new_secure_random_alphanumeric(32)
    }

    # encrypted_settings_key_base is optional for now
    if ENV['GITLAB_GENERATE_ENCRYPTED_SETTINGS_KEY_BASE']
      defaults[:encrypted_settings_key_base] = generate_new_secure_token
    end

    missing_secrets = set_missing_keys(defaults)
    write_secrets_yml!(missing_secrets) if missing_secrets.any?
  end

  def generate_new_secure_token
    SecureRandom.hex(64)
  end

  def generate_new_rsa_private_key
    OpenSSL::PKey::RSA.new(2048).to_pem
  end

  def generate_new_secure_random_alphanumeric(chars)
    SecureRandom.alphanumeric(chars)
  end

  def warn_missing_secret(secret)
    return if rails_env.test?

    warn "Missing Rails.application.credentials.#{secret} for #{rails_env} environment. " \
      "The secret will be generated and stored in config/secrets.yml."
  end

  def set_missing_keys(defaults)
    defaults.each_with_object({}) do |(key, default), missing|
      next if Rails.application.credentials.public_send(key).present?

      warn_missing_secret(key)

      missing[key] = Rails.application.credentials[key] = default
    end
  end

  def write_secrets_yml!(missing_secrets)
    secrets_from_file[rails_env.to_s] ||= {}
    secrets_from_file[rails_env.to_s].merge!(missing_secrets)

    backup_file = "#{secrets_file_path}.orig.#{Time.now.to_i}"
    if File.exist?(secrets_file_path)
      warn "Creating a backup of secrets file: #{secrets_file_path}: #{backup_file}"
      FileUtils.mv(secrets_file_path, backup_file)
    end

    File.write(
      secrets_file_path,
      YAML.dump(secrets_from_file.deep_stringify_keys),
      mode: 'w', perm: 0o600
    )
  end
end

SecretsInitializer.new(secrets_file_path: Rails.root.join('config/secrets.yml'), rails_env: Rails.env).execute!
