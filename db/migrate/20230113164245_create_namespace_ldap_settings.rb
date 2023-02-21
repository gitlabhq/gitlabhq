# frozen_string_literal: true

class CreateNamespaceLdapSettings < Gitlab::Database::Migration[2.1]
  def change
    create_table :namespace_ldap_settings, if_not_exists: true, id: false do |t|
      t.references :namespace, primary_key: true, default: nil,
        type: :bigint, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.column :sync_last_start_at, :datetime_with_timezone
      t.column :sync_last_update_at, :datetime_with_timezone
      t.column :sync_last_successful_at, :datetime_with_timezone
      t.integer :sync_status, null: false, default: 0, limit: 2
      t.text :sync_error, limit: 255
    end
  end
end
