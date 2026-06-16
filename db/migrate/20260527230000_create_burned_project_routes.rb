# frozen_string_literal: true

class CreateBurnedProjectRoutes < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :burned_project_routes do |t|
      t.bigint :organization_id, null: false
      t.bigint :project_id, null: false
      t.datetime_with_timezone :burned_at, null: false
      t.timestamps_with_timezone null: false
      t.text :path, null: false, limit: 255

      t.index 'organization_id, LOWER(path)',
        unique: true,
        name: 'index_burned_project_routes_on_org_id_lower_path'
      t.foreign_key :organizations, column: :organization_id, on_delete: :cascade
    end
  end
end
