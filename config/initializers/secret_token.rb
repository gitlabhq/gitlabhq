# Be sure to restart your server when you modify this file.

require 'securerandom'

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

def find_secure_token
  token_file = Rails.root.join('.secret')
  if ENV.key?('SECRET_KEY_BASE')
    ENV['SECRET_KEY_BASE']
  elsif File.exist? token_file
    # Use the existing token.
    File.read(token_file).chomp
  else
    # Generate a new token of 64 random hexadecimal characters and store it in token_file.
    token = SecureRandom.hex(64)
    File.write(token_file, token)
    token
  end
end

Rails.application.config.secret_token = find_secure_token
Rails.application.config.secret_key_base = find_secure_token

# CI
def generate_new_secure_token
  SecureRandom.hex(64)
end

if Rails.application.secrets.db_key_base.blank?
  warn "Missing `db_key_base` for '#{Rails.env}' environment. The secrets will be generated and stored in `config/secrets.yml`"

  all_secrets = YAML.load_file('config/secrets.yml') if File.exist?('config/secrets.yml')
  all_secrets ||= {}

  # generate secrets
  env_secrets = all_secrets[Rails.env.to_s] || {}
  env_secrets['db_key_base'] ||= generate_new_secure_token
  all_secrets[Rails.env.to_s] = env_secrets

  # save secrets
  File.open('config/secrets.yml', 'w', 0600) do |file|
    file.write(YAML.dump(all_secrets))
  end

  Rails.application.secrets.db_key_base = env_secrets['db_key_base']
end
