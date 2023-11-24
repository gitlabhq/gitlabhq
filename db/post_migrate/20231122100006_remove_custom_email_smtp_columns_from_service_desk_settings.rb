# frozen_string_literal: true

class RemoveCustomEmailSmtpColumnsFromServiceDeskSettings < Gitlab::Database::Migration[2.2]
  MAXIMUM_LIMIT = 255

  milestone '16.7'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :service_desk_settings, :custom_email_smtp_address
      remove_column :service_desk_settings, :custom_email_smtp_port
      remove_column :service_desk_settings, :custom_email_smtp_username
      remove_column :service_desk_settings, :encrypted_custom_email_smtp_password
      remove_column :service_desk_settings, :encrypted_custom_email_smtp_password_iv
    end
  end

  def down
    with_lock_retries do
      add_column :service_desk_settings, :custom_email_smtp_address, :text
      add_column :service_desk_settings, :custom_email_smtp_port, :integer
      add_column :service_desk_settings, :custom_email_smtp_username, :text
      add_column :service_desk_settings, :encrypted_custom_email_smtp_password, :binary
      add_column :service_desk_settings, :encrypted_custom_email_smtp_password_iv, :binary
    end

    add_text_limit :service_desk_settings, :custom_email_smtp_address, MAXIMUM_LIMIT
    add_text_limit :service_desk_settings, :custom_email_smtp_username, MAXIMUM_LIMIT
  end
end
