# frozen_string_literal: true

class AddSmtpAuthenticationToServiceDeskCustomEmailCredentials < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  def change
    add_column :service_desk_custom_email_credentials, :smtp_authentication, :integer,
      limit: 2, null: true, default: nil
  end
end
