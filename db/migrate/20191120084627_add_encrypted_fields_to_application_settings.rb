# frozen_string_literal: true

class AddEncryptedFieldsToApplicationSettings < ActiveRecord::Migration[5.2]
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

  def up
    PLAINTEXT_ATTRIBUTES.each do |plaintext_attribute|
      add_column :application_settings, "encrypted_#{plaintext_attribute}", :text
      add_column :application_settings, "encrypted_#{plaintext_attribute}_iv", :string, limit: 255
    end
  end

  def down
    PLAINTEXT_ATTRIBUTES.each do |plaintext_attribute|
      remove_column :application_settings, "encrypted_#{plaintext_attribute}"
      remove_column :application_settings, "encrypted_#{plaintext_attribute}_iv"
    end
  end
end
