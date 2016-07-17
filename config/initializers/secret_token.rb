# Be sure to restart your server when you modify this file.

require 'securerandom'

def generate_new_secure_token
  SecureRandom.hex(64)
end

def warn_missing_secret(secret)
  warn "Missing `#{secret}` for '#{Rails.env}' environment. The secret will be generated and stored in `config/secrets.yml`"
end

def create_tokens
  secret_file = Rails.root.join('.secret')
  file_key = File.read(secret_file).chomp if File.exist?(secret_file)
  env_key = ENV['SECRET_KEY_BASE']
  yaml_additions = {}

  defaults = {
    secret_key_base: env_key || file_key || generate_new_secure_token,
    otp_key_base: env_key || file_key || generate_new_secure_token,
    db_key_base: generate_new_secure_token
  }

  defaults.stringify_keys.each do |key, default|
    if Rails.application.secrets[key].blank?
      warn_missing_secret(key)

      yaml_additions[key] = Rails.application.secrets[key] = default
    end
  end

  unless yaml_additions.empty?
    secrets_yml = Rails.root.join('config/secrets.yml')
    all_secrets = YAML.load_file(secrets_yml) if File.exist?(secrets_yml)
    all_secrets ||= {}

    env_secrets = all_secrets[Rails.env.to_s] || {}
    all_secrets[Rails.env.to_s] = env_secrets.merge(yaml_additions)

    File.write(secrets_yml, YAML.dump(all_secrets), mode: 'w', perm: 0600)
  end

  begin
    File.delete(secret_file) if file_key
  rescue => e
    warn "Error deleting useless .secret file: #{e}"
  end
end

create_tokens
