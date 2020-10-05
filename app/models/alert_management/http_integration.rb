# frozen_string_literal: true

module AlertManagement
  class HttpIntegration < ApplicationRecord
    belongs_to :project, inverse_of: :alert_management_http_integrations

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_truncated,
      algorithm: 'aes-256-gcm'

    validates :project, presence: true
    validates :active, inclusion: { in: [true, false] }

    validates :token, presence: true
    validates :name, presence: true, length: { maximum: 255 }
    validates :endpoint_identifier, presence: true, length: { maximum: 255 }
    validates :endpoint_identifier, uniqueness: { scope: [:project_id, :active] }, if: :active?

    before_validation :prevent_token_assignment
    before_validation :ensure_token

    private

    def prevent_token_assignment
      if token.present? && token_changed?
        self.token = nil
        self.encrypted_token = encrypted_token_was
        self.encrypted_token_iv = encrypted_token_iv_was
      end
    end

    def ensure_token
      self.token = generate_token if token.blank?
    end

    def generate_token
      SecureRandom.hex
    end
  end
end
