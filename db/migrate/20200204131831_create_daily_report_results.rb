# frozen_string_literal: true

class CreateDailyReportResults < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :ci_daily_report_results do |t|
      t.date :date, null: false
      t.bigint :project_id, null: false
      t.bigint :last_pipeline_id, null: false
      t.float :value, null: false
      t.integer :param_type, limit: 8, null: false
      t.string :ref_path, null: false
      t.string :title, null: false

      t.index :last_pipeline_id
      t.index [:project_id, :ref_path, :param_type, :date, :title], name: 'index_daily_report_results_unique_columns', unique: true
      t.foreign_key :projects, on_delete: :cascade
      t.foreign_key :ci_pipelines, column: :last_pipeline_id, on_delete: :cascade
    end
  end
  # rubocop:enable Migration/PreventStrings
end
