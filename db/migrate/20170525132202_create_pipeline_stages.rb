class CreatePipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_stages do |t|
      t.integer :project_id
      t.integer :pipeline_id
      t.string :name
      t.timestamps null: true
    end
  end
end
