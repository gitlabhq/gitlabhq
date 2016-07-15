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
  secret_key_base = env_key.present? ? env_key : file_key

  if secret_key_base.blank?
    secret_key_base = generate_new_secure_token
    File.write(secret_file, secret_key_base)
  end

  Rails.application.config.secret_key_base = secret_key_base

  otp_key_base = Rails.application.secrets.otp_key_base
  db_key_base = Rails.application.secrets.db_key_base
  yaml_additions = {}

  if otp_key_base.blank?
    warn_missing_secret('otp_key_base')

    otp_key_base ||= env_key || file_key || generate_new_secure_token
    yaml_additions['otp_key_base'] = otp_key_base
  end

  Rails.application.secrets.otp_key_base = otp_key_base

  if db_key_base.blank?
    warn_missing_secret('db_key_base')

    yaml_additions['db_key_base'] = db_key_base = generate_new_secure_token
  end

  Rails.application.secrets.db_key_base = db_key_base

  unless yaml_additions.empty?
    secrets_yml = Rails.root.join('config/secrets.yml')
    all_secrets = YAML.load_file(secrets_yml) if File.exist?(secrets_yml)
    all_secrets ||= {}

    env_secrets = all_secrets[Rails.env.to_s] || {}
    all_secrets[Rails.env.to_s] = env_secrets.merge(yaml_additions)

    File.write(secrets_yml, YAML.dump(all_secrets), mode: 'w', perm: 0600)
  end
end

create_tokens
