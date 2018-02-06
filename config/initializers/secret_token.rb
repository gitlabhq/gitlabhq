# Be sure to restart your server when you modify this file.

require 'securerandom'

# Transition material in .secret to the secret_key_base key in config/secrets.yml.
# Historically, ENV['SECRET_KEY_BASE'] takes precedence over .secret, so we maintain that
# behavior.
#
# It also used to be the case that the key material in ENV['SECRET_KEY_BASE'] or .secret
# was used to encrypt OTP (two-factor authentication) data so if present, we copy that key
# material into config/secrets.yml under otp_key_base.
#
# Finally, if we have successfully migrated all secrets to config/secrets.yml, delete the
# .secret file to avoid confusion.
#
def create_tokens
  secret_file = Rails.root.join('.secret')
  file_secret_key = File.read(secret_file).chomp if File.exist?(secret_file)
  env_secret_key = ENV['SECRET_KEY_BASE']

  # Ensure environment variable always overrides secrets.yml.
  Rails.application.secrets.secret_key_base = env_secret_key if env_secret_key.present?

  defaults = {
    secret_key_base: file_secret_key || generate_new_secure_token,
    otp_key_base: env_secret_key || file_secret_key || generate_new_secure_token,
    db_key_base: generate_new_secure_token,
    openid_connect_signing_key: generate_new_rsa_private_key
  }

  missing_secrets = set_missing_keys(defaults)
  write_secrets_yml(missing_secrets) unless missing_secrets.empty?

  begin
    File.delete(secret_file) if file_secret_key
  rescue => e
    warn "Error deleting useless .secret file: #{e}"
  end
end

def generate_new_secure_token
  SecureRandom.hex(64)
end

def generate_new_rsa_private_key
  OpenSSL::PKey::RSA.new(2048).to_pem
end

def warn_missing_secret(secret)
  warn "Missing Rails.application.secrets.#{secret} for #{Rails.env} environment. The secret will be generated and stored in config/secrets.yml."
end

def set_missing_keys(defaults)
  defaults.stringify_keys.each_with_object({}) do |(key, default), missing|
    if Rails.application.secrets[key].blank?
      warn_missing_secret(key)

      missing[key] = Rails.application.secrets[key] = default
    end
  end
end

def write_secrets_yml(missing_secrets)
  secrets_yml = Rails.root.join('config/secrets.yml')
  rails_env = Rails.env.to_s
  secrets = YAML.load_file(secrets_yml) if File.exist?(secrets_yml)
  secrets ||= {}
  secrets[rails_env] ||= {}

  secrets[rails_env].merge!(missing_secrets) do |key, old, new|
    # Previously, it was possible this was set to the literal contents of an Erb
    # expression that evaluated to an empty value. We don't want to support that
    # specifically, just ensure we don't break things further.
    #
    if old.present?
      warn <<EOM
Rails.application.secrets.#{key} was blank, but the literal value in config/secrets.yml was:
  #{old}

This probably isn't the expected value for this secret. To keep using a literal Erb string in config/secrets.yml, replace `<%` with `<%%`.
EOM

      exit 1 # rubocop:disable Rails/Exit
    end

    new
  end

  File.write(secrets_yml, YAML.dump(secrets), mode: 'w', perm: 0600)
end

create_tokens
