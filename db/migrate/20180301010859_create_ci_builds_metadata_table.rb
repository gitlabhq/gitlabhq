class CreateCiBuildsMetadataTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_builds_metadata, id: false do |t|
      t.integer :build_id, null: false
      t.integer :project_id, null: false
      t.integer :timeout
      t.integer :timeout_source, null: false, default: 1

      t.primary_key :build_id
      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade
      t.foreign_key :projects, column: :project_id, on_delete: :cascade

      t.index :project_id
    end
  end
end
