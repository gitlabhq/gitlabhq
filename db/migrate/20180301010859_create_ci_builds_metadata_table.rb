class CreateCiBuildsMetadataTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_builds_metadata do |t|
      t.integer :build_id, null: false
      t.integer :project_id, null: false
      t.integer :timeout
      t.integer :timeout_source, null: false, default: 1

      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade
      t.foreign_key :projects, column: :project_id, on_delete: :cascade

      t.index :build_id, unique: true
      t.index :project_id
    end
  end
end
