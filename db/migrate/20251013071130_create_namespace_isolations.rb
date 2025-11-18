# frozen_string_literal: true

class CreateNamespaceIsolations < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    create_table :namespace_isolations do |t|
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :isolated, null: false, default: false

      t.index :namespace_id, unique: true
      t.foreign_key :namespaces, column: :namespace_id, on_delete: :cascade
    end
  end
end
