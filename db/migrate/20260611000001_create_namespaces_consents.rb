# frozen_string_literal: true

class CreateNamespacesConsents < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  def up
    create_table :namespaces_consents do |t|
      t.bigint :namespace_id, null: false
      t.bigint :user_id, null: true
      t.integer :feature_name, null: false, limit: 2
      t.timestamps_with_timezone null: false

      t.index :user_id, name: 'index_namespaces_consents_on_user_id'
      t.index [:namespace_id, :feature_name],
        unique: true,
        name: 'index_namespaces_consents_on_namespace_id_and_feature_name'
    end

    add_concurrent_foreign_key :namespaces_consents, :namespaces,
      column: :namespace_id,
      on_delete: :cascade
  end

  def down
    drop_table :namespaces_consents
  end
end
