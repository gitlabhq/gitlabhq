# rubocop:disable Migration/Timestamps
class CreatePipelineStages < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :ci_stages do |t|
      t.integer :project_id
      t.integer :pipeline_id
      t.timestamps null: true
      t.string :name
    end

    add_concurrent_foreign_key :ci_stages, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :ci_stages, :ci_pipelines, column: :pipeline_id, on_delete: :cascade
    add_concurrent_index :ci_stages, :project_id
    add_concurrent_index :ci_stages, :pipeline_id
  end

  def down
    drop_table :ci_stages
  end
end
