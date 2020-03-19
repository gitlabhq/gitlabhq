# frozen_string_literal: true

Gitlab.ee do
  public_key_file = File.read(Rails.root.join(".license_encryption_key.pub"))
  public_key = OpenSSL::PKey::RSA.new(public_key_file)
  Gitlab::License.encryption_key = public_key
rescue
  warn "WARNING: No valid license encryption key provided."
end
