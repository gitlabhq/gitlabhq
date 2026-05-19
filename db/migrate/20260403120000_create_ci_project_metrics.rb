# frozen_string_literal: true

class CreateCiProjectMetrics < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    create_table :ci_project_metrics do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.datetime_with_timezone :first_pipeline_succeeded_at

      t.index :project_id, unique: true
    end
  end

  def down
    drop_table :ci_project_metrics, if_exists: true
  end
end
