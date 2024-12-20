# frozen_string_literal: true

class CreateSystemAccessInstanceMicrosoftApplications < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :system_access_instance_microsoft_applications do |t|
      t.timestamps_with_timezone null: false
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
