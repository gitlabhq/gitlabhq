# frozen_string_literal: true

# Stores the authentication data required to access another GitLab instance on
# behalf of a user, to import Groups and Projects directly from that instance.
class BulkImports::Configuration < ApplicationRecord
  self.table_name = 'bulk_import_configurations'

  belongs_to :bulk_import, inverse_of: :configuration, optional: false

  validates :url, :access_token, length: { maximum: 255 }, presence: true
  validates :url, public_url: { schemes: %w[http https], enforce_sanitization: true, ascii_only: true },
    allow_nil: true

  attr_encrypted :url,
    key: Settings.attr_encrypted_db_key_base_32,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm'
  attr_encrypted :access_token,
    key: Settings.attr_encrypted_db_key_base_32,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm'

  def safe_url
    return '' if url.blank?

    Gitlab::UrlSanitizer.sanitize(url)
  end
end
