# frozen_string_literal: true

class CreateSystemAccessGroupMicrosoftApplications < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  def change
    create_table :system_access_group_microsoft_applications do |t|
      t.timestamps_with_timezone null: false
      t.references :group, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
      t.bigint :temp_source_id, index: { unique: true, name: 'index_group_microsoft_applications_on_temp_source_id' },
        comment: 'Temporary column to store graph access tokens id'
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
