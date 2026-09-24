# frozen_string_literal: true

class CreateSecNamespaceMirrors < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    create_table :sec_namespace_mirrors, id: false do |t|
      t.bigint :namespace_id, primary_key: true, default: nil
      t.bigint :organization_id, null: false
      t.bigint :traversal_ids, array: true, default: [], null: false

      t.index [:organization_id, :namespace_id]
      t.index :traversal_ids, using: :gin, name: 'index_gin_sec_namespace_mirrors_on_traversal_ids'
      t.index '(traversal_ids[1]), (traversal_ids[2]), (traversal_ids[3]), (traversal_ids[4])',
        include: [:traversal_ids, :namespace_id],
        name: 'index_sec_namespace_mirrors_on_traversal_ids_unnest'
    end
  end
end
