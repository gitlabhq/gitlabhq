class CreateProjectStatistics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # use bigint columns to support values >2GB
    counter_column = { limit: 8, null: false, default: 0 }

    create_table :project_statistics do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :namespace, null: false, index: true
      t.integer :commit_count, counter_column
      t.integer :storage_size, counter_column
      t.integer :repository_size, counter_column
      t.integer :lfs_objects_size, counter_column
      t.integer :build_artifacts_size, counter_column
    end
  end
end
