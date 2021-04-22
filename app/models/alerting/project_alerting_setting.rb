# frozen_string_literal: true

require 'securerandom'

module Alerting
  class ProjectAlertingSetting < ApplicationRecord
    belongs_to :project

    validates :token, presence: true

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm'

    before_validation :ensure_token

    private

    def ensure_token
      self.token ||= generate_token
    end

    def generate_token
      SecureRandom.hex
    end
  end
end
