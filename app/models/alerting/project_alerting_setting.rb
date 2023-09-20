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
    after_create :create_http_integration
    after_update :sync_http_integration

    private

    def ensure_token
      self.token ||= generate_token
    end

    def generate_token
      SecureRandom.hex
    end

    # Remove in next required stop after %16.4
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338838
    def sync_http_integration
      project.alert_management_http_integrations
        .for_endpoint_identifier('legacy-prometheus')
        .take
        &.update_columns(
          encrypted_token: encrypted_token,
          encrypted_token_iv: encrypted_token_iv
        )
    end

    # Remove in next required stop after %16.4
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338838
    def create_http_integration
      AlertManagement::HttpIntegration.insert({
        project_id: project_id,
        encrypted_token: encrypted_token,
        encrypted_token_iv: encrypted_token_iv,
        active: true,
        name: 'Prometheus',
        endpoint_identifier: 'legacy-prometheus',
        type_identifier: :prometheus
      })
    end
  end
end
