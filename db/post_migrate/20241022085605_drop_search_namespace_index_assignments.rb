# frozen_string_literal: true

class DropSearchNamespaceIndexAssignments < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    drop_table :search_namespace_index_assignments
  end

  def down
    create_table :search_namespace_index_assignments do |t|
      t.references :namespace, foreign_key: true, null: true, on_delete: :nullify
      t.bigint :search_index_id, index: true, null: false
      t.bigint :namespace_id_non_nullable, null: false
      t.timestamps_with_timezone null: false
      t.integer :namespace_id_hashed, null: false
      t.text :index_type, null: false, limit: 255
    end

    add_index :search_namespace_index_assignments,
      [:namespace_id, :index_type],
      unique: true,
      name: 'index_search_namespace_index_assignments_uniqueness_index_type'

    add_index :search_namespace_index_assignments,
      [:namespace_id, :search_index_id],
      unique: true,
      name: 'index_search_namespace_index_assignments_uniqueness_on_index_id'
  end
end
