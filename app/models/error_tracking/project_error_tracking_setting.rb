# frozen_string_literal: true

module ErrorTracking
  class ProjectErrorTrackingSetting < ActiveRecord::Base
    belongs_to :project

    validates :api_url, length: { maximum: 255 }, public_url: true, url: { enforce_sanitization: true }

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_truncated,
      algorithm: 'aes-256-gcm'
  end
end
