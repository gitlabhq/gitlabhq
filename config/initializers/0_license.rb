# frozen_string_literal: true

load_license = lambda do |dir:, license_name:|
  prefix = ENV['GITLAB_LICENSE_MODE'] == 'test' ? 'test_' : ''
  public_key_file = File.read(Rails.root.join(dir, ".#{prefix}license_encryption_key.pub"))
  public_key = OpenSSL::PKey::RSA.new(public_key_file)
  Gitlab::License.encryption_key = public_key
rescue StandardError
  warn "WARNING: No valid #{license_name} encryption key provided."
end

Gitlab.ee do
  load_license.call(dir: '.', license_name: 'license')
end

Gitlab.jh do
  load_license.call(dir: 'jh', license_name: 'JH license')
end
