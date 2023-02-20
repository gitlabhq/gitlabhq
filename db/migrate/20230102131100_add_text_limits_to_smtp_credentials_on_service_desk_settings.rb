# frozen_string_literal: true

class AddTextLimitsToSmtpCredentialsOnServiceDeskSettings < Gitlab::Database::Migration[2.1]
  MAXIMUM_LIMIT = 255

  disable_ddl_transaction!

  def up
    add_text_limit :service_desk_settings, :custom_email, MAXIMUM_LIMIT
    add_text_limit :service_desk_settings, :custom_email_smtp_address, MAXIMUM_LIMIT
    add_text_limit :service_desk_settings, :custom_email_smtp_username, MAXIMUM_LIMIT
  end

  def down
    remove_text_limit :service_desk_settings, :custom_email
    remove_text_limit :service_desk_settings, :custom_email_smtp_address
    remove_text_limit :service_desk_settings, :custom_email_smtp_username
  end
end
