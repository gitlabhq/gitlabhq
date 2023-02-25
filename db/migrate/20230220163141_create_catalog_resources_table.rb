# frozen_string_literal: true

class CreateCatalogResourcesTable < Gitlab::Database::Migration[2.1]
  def change
    create_table :catalog_resources do |t|
      t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone :created_at, null: false
    end
  end
end
