# frozen_string_literal: true

class EncryptPlaintextAttributesOnApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  PLAINTEXT_ATTRIBUTES = %w[
    akismet_api_key
    elasticsearch_aws_secret_access_key
    recaptcha_private_key
    recaptcha_site_key
    slack_app_secret
    slack_app_verification_token
  ].freeze

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'

    def self.encryption_options_base_32_aes_256_gcm
      {
        mode: :per_attribute_iv,
        key: Gitlab::Utils.ensure_utf8_size(Rails.application.secrets.db_key_base, bytes: 32.bytes),
        algorithm: 'aes-256-gcm',
        encode: true
      }
    end

    attr_encrypted :akismet_api_key, encryption_options_base_32_aes_256_gcm
    attr_encrypted :elasticsearch_aws_secret_access_key, encryption_options_base_32_aes_256_gcm
    attr_encrypted :recaptcha_private_key, encryption_options_base_32_aes_256_gcm
    attr_encrypted :recaptcha_site_key, encryption_options_base_32_aes_256_gcm
    attr_encrypted :slack_app_secret, encryption_options_base_32_aes_256_gcm
    attr_encrypted :slack_app_verification_token, encryption_options_base_32_aes_256_gcm

    def akismet_api_key
      decrypt(:akismet_api_key, self[:encrypted_akismet_api_key]) || self[:akismet_api_key]
    end

    def elasticsearch_aws_secret_access_key
      decrypt(:elasticsearch_aws_secret_access_key, self[:encrypted_elasticsearch_aws_secret_access_key]) || self[:elasticsearch_aws_secret_access_key]
    end

    def recaptcha_private_key
      decrypt(:recaptcha_private_key, self[:encrypted_recaptcha_private_key]) || self[:recaptcha_private_key]
    end

    def recaptcha_site_key
      decrypt(:recaptcha_site_key, self[:encrypted_recaptcha_site_key]) || self[:recaptcha_site_key]
    end

    def slack_app_secret
      decrypt(:slack_app_secret, self[:encrypted_slack_app_secret]) || self[:slack_app_secret]
    end

    def slack_app_verification_token
      decrypt(:slack_app_verification_token, self[:encrypted_slack_app_verification_token]) || self[:slack_app_verification_token]
    end
  end

  def up
    ApplicationSetting.find_each do |application_setting|
      # We are using the setter from attr_encrypted gem to encrypt the data.
      # The gem updates the two columns needed to decrypt the value:
      # - "encrypted_#{plaintext_attribute}"
      # - "encrypted_#{plaintext_attribute}_iv"
      application_setting.assign_attributes(
        PLAINTEXT_ATTRIBUTES.each_with_object({}) do |plaintext_attribute, attributes|
          attributes[plaintext_attribute] = application_setting.send(plaintext_attribute)
        end
      )
      application_setting.save(validate: false)
    end
  end

  def down
    ApplicationSetting.find_each do |application_setting|
      application_setting.update_columns(
        PLAINTEXT_ATTRIBUTES.each_with_object({}) do |plaintext_attribute, attributes|
          attributes[plaintext_attribute] = application_setting.send(plaintext_attribute)
          attributes["encrypted_#{plaintext_attribute}"] = nil
          attributes["encrypted_#{plaintext_attribute}_iv"] = nil
        end
      )
    end
  end
end
