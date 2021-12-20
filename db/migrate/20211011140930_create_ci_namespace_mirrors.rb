# frozen_string_literal: true

class CreateCiNamespaceMirrors < Gitlab::Database::Migration[1.0]
  TABLE_NAME = :ci_namespace_mirrors
  INDEX_NAME = "index_gin_#{TABLE_NAME}_on_traversal_ids"

  def change
    create_table TABLE_NAME do |t|
      t.integer :namespace_id, null: false, index: { unique: true }
      t.integer :traversal_ids, array: true, default: [], null: false

      t.index :traversal_ids, name: INDEX_NAME, using: :gin
    end
  end
end
