# frozen_string_literal: true

class CreateCatalogVerifiedNamespaces < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    create_table :catalog_verified_namespaces do |t|
      t.references :namespace, index: { unique: true }, null: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
      t.integer :verification_level, null: false, limit: 2, default: 0
    end
  end
end
