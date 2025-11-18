# frozen_string_literal: true

class DropInstanceMicrosoftTables < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    drop_table :system_access_instance_microsoft_graph_access_tokens, if_exists: true

    drop_table :system_access_instance_microsoft_applications, if_exists: true
  end

  def down
    create_table :system_access_instance_microsoft_applications, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false
      t.boolean :enabled, null: false, default: false
      t.text :tenant_xid, null: false, limit: 255
      t.text :client_xid, null: false, limit: 255
      t.text :login_endpoint, null: false, limit: 255, default: 'https://login.microsoftonline.com'
      t.text :graph_endpoint, null: false, limit: 255, default: 'https://graph.microsoft.com'
      t.binary :encrypted_client_secret, null: false
      t.binary :encrypted_client_secret_iv, null: false
    end

    create_table :system_access_instance_microsoft_graph_access_tokens, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false
      t.references :system_access_instance_microsoft_application,
        index: { name: 'unique_index_instance_ms_access_tokens_on_ms_app_id', unique: true },
        foreign_key: { on_delete: :cascade }
      t.integer :expires_in, null: false
      t.binary :encrypted_token, null: false
      t.binary :encrypted_token_iv, null: false
    end
  end
end
