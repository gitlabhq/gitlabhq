# frozen_string_literal: true

module ServiceDesk
  class CustomEmailCredential < ApplicationRecord
    attr_encrypted :smtp_username,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      encode: false,
      encode_iv: false
    attr_encrypted :smtp_password,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      encode: false,
      encode_iv: false

    belongs_to :project

    validates :project, presence: true

    validates :smtp_address,
      presence: true,
      length: { maximum: 255 },
      hostname: { allow_numeric_hostname: true }
    validate :validate_smtp_address

    validates :smtp_port,
      presence: true,
      numericality: { only_integer: true, greater_than: 0 }

    validates :smtp_username,
      presence: true,
      length: { maximum: 255 }
    validates :smtp_password,
      presence: true,
      length: { minimum: 8, maximum: 128 }

    delegate :service_desk_setting, to: :project

    def delivery_options
      {
        user_name: smtp_username,
        password: smtp_password,
        address: smtp_address,
        domain: Mail::Address.new(service_desk_setting.custom_email).domain,
        port: smtp_port || 587
      }
    end

    private

    def validate_smtp_address
      # Addressable::URI always needs a scheme otherwise it interprets the host as the path
      Gitlab::UrlBlocker.validate!("smtp://#{smtp_address}",
        schemes: %w[smtp],
        ascii_only: true,
        enforce_sanitization: true,
        allow_localhost: false,
        allow_local_network: false
      )
    rescue Gitlab::UrlBlocker::BlockedUrlError => e
      errors.add(:smtp_address, e)
    end
  end
end
