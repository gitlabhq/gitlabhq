# frozen_string_literal: true

load_license = ->(dir:, license_name:) do
  begin
    public_key_file = File.read(Rails.root.join(dir, ".license_encryption_key.pub"))
    public_key = OpenSSL::PKey::RSA.new(public_key_file)
    Gitlab::License.encryption_key = public_key
  rescue StandardError
    warn "WARNING: No valid #{license_name} encryption key provided."
  end

  begin
    if Rails.env.development? || Rails.env.test? || ENV['GITLAB_LICENSE_MODE'] == 'test'
      fallback_key_file = File.read(Rails.root.join(dir, ".test_license_encryption_key.pub"))
      fallback_key = OpenSSL::PKey::RSA.new(fallback_key_file)
      Gitlab::License.fallback_decryption_keys = [fallback_key]
    end
  rescue StandardError
    warn "WARNING: No fallback #{license_name} decryption key provided."
  end
end

Gitlab.ee do
  load_license.call(dir: '.', license_name: 'license')
end

Gitlab.jh do
  load_license.call(dir: 'jh', license_name: 'JH license')
end
