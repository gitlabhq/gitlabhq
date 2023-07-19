# frozen_string_literal: true

class CreateSystemAccessMicrosoftApplication < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :system_access_microsoft_applications do |t|
      t.timestamps_with_timezone null: false
      t.references :namespace, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.boolean :enabled, null: false, default: false
      t.text :tenant_xid, null: false, limit: 255
      t.text :client_xid, null: false, limit: 255
      t.text :login_endpoint, null: false, limit: 255, default: 'https://login.microsoftonline.com'
      t.text :graph_endpoint, null: false, limit: 255, default: 'https://graph.microsoft.com'
      t.binary :encrypted_client_secret, null: false
      t.binary :encrypted_client_secret_iv, null: false
    end
  end
end
