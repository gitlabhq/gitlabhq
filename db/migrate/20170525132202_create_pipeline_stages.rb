class CreatePipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_stages do |t|
      t.integer :project_id
      t.integer :pipeline_id
      t.timestamps null: true
      t.string :name
    end
  end
end
