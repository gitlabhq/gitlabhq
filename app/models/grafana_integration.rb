# frozen_string_literal: true

class GrafanaIntegration < ApplicationRecord
  belongs_to :project

  attr_encrypted :token,
    mode:      :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key:       Settings.attr_encrypted_db_key_base_32

  validates :grafana_url,
            length: { maximum: 1024 },
            addressable_url: { enforce_sanitization: true, ascii_only: true }

  validates :token, :project, presence: true

  validates :enabled, inclusion: { in: [true, false] }

  scope :enabled, -> { where(enabled: true) }

  def client
    return unless enabled?

    @client ||= ::Grafana::Client.new(api_url: grafana_url.chomp('/'), token: token)
  end
end
