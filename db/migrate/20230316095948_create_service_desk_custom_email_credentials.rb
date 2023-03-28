# frozen_string_literal: true

class CreateServiceDeskCustomEmailCredentials < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table(:service_desk_custom_email_credentials, id: false) do |t|
      t.references :project,
        primary_key: true,
        default: nil,
        index: false,
        foreign_key: { to_table: :projects, on_delete: :cascade }
      t.timestamps_with_timezone
      t.integer :smtp_port
      t.text :smtp_address, limit: 255
      t.binary :encrypted_smtp_username
      t.binary :encrypted_smtp_username_iv
      t.binary :encrypted_smtp_password
      t.binary :encrypted_smtp_password_iv
    end
  end
end
