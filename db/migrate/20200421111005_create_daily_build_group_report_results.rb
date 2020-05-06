# frozen_string_literal: true

class CreateDailyBuildGroupReportResults < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :ci_daily_build_group_report_results do |t|
      t.date :date, null: false
      t.bigint :project_id, null: false
      t.bigint :last_pipeline_id, null: false
      t.text :ref_path, null: false # rubocop:disable Migration/AddLimitToTextColumns
      t.text :group_name, null: false # rubocop:disable Migration/AddLimitToTextColumns
      t.jsonb :data, null: false

      t.index :last_pipeline_id
      t.index [:project_id, :ref_path, :date, :group_name], name: 'index_daily_build_group_report_results_unique_columns', unique: true
      t.foreign_key :projects, on_delete: :cascade
      t.foreign_key :ci_pipelines, column: :last_pipeline_id, on_delete: :cascade
    end
  end
end
