# frozen_string_literal: true

class GrafanaIntegration < ApplicationRecord
  belongs_to :project

  attr_encrypted :token,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key: Settings.attr_encrypted_db_key_base_32

  before_validation :check_token_changes

  validates :grafana_url,
    length: { maximum: 1024 },
    addressable_url: { enforce_sanitization: true, ascii_only: true }

  validates :encrypted_token, :project, presence: true

  validates :enabled, inclusion: { in: [true, false] }

  before_validation :reset_token

  scope :enabled, -> { where(enabled: true) }

  def client
    return unless enabled?

    @client ||= ::Grafana::Client.new(api_url: grafana_url.chomp('/'), token: token)
  end

  def masked_token
    mask(encrypted_token)
  end

  def masked_token_was
    mask(encrypted_token_was)
  end

  private

  def reset_token
    if grafana_url_changed? && !encrypted_token_changed?
      self.token = nil
    end
  end

  def token
    attr_decrypt(:token, encrypted_token)
  end

  def check_token_changes
    return unless [encrypted_token_was, masked_token_was].include?(token)

    clear_attribute_changes [:token, :encrypted_token, :encrypted_token_iv]
  end

  def mask(token)
    token&.squish&.gsub(/./, '*')
  end
end
