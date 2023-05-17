# frozen_string_literal: true

class AddServiceDeskCustomEmailVerifications < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table(:service_desk_custom_email_verifications, id: false, primary_key: :project_id) do |t|
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.references :triggerer, index: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps_with_timezone
      t.datetime_with_timezone :triggered_at
      t.integer :state, limit: 2, null: false, default: 0
      t.integer :error, limit: 2
      t.binary :encrypted_token
      t.binary :encrypted_token_iv
    end

    execute "ALTER TABLE service_desk_custom_email_verifications ADD PRIMARY KEY (project_id);"
  end

  def down
    drop_table :service_desk_custom_email_verifications
  end
end
