# frozen_string_literal: true

class CreateNamespaceSecretCounts < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :namespace_secret_counts, id: false, if_not_exists: true do |t|
      t.bigint :namespace_id, primary_key: true, default: nil
      t.bigint :root_namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :count, null: false, default: 0

      t.index :root_namespace_id, name: 'index_namespace_secret_counts_on_root_namespace_id'
      t.foreign_key :namespaces, column: :namespace_id, on_delete: :cascade
      t.foreign_key :namespaces, column: :root_namespace_id, on_delete: :cascade
    end
  end
end
