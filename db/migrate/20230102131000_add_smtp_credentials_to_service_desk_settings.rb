# frozen_string_literal: true

class AddSmtpCredentialsToServiceDeskSettings < Gitlab::Database::Migration[2.1]
  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20230102131100_add_text_limits_to_smtp_credentials_on_service_desk_settings.rb
    add_column :service_desk_settings, :custom_email_enabled, :boolean, default: false, null: false
    # Unique constraint/index is added in 20230102131050_add_unique_constraint_for_custom_email_to_...
    add_column :service_desk_settings, :custom_email, :text
    add_column :service_desk_settings, :custom_email_smtp_address, :text
    add_column :service_desk_settings, :custom_email_smtp_port, :integer
    add_column :service_desk_settings, :custom_email_smtp_username, :text
    # Encrypted attribute via attr_encrypted needs these two columns
    add_column :service_desk_settings, :encrypted_custom_email_smtp_password, :binary
    add_column :service_desk_settings, :encrypted_custom_email_smtp_password_iv, :binary
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :service_desk_settings, :custom_email_enabled
    remove_column :service_desk_settings, :custom_email
    remove_column :service_desk_settings, :custom_email_smtp_address
    remove_column :service_desk_settings, :custom_email_smtp_port
    remove_column :service_desk_settings, :custom_email_smtp_username
    remove_column :service_desk_settings, :encrypted_custom_email_smtp_password
    remove_column :service_desk_settings, :encrypted_custom_email_smtp_password_iv
  end
end
