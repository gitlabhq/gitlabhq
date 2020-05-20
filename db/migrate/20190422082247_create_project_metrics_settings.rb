# frozen_string_literal: true

class CreateProjectMetricsSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_metrics_settings, id: :int, primary_key: :project_id, default: nil do |t|
      t.string :external_dashboard_url, null: false # rubocop:disable Migration/PreventStrings
      t.foreign_key :projects, column: :project_id, on_delete: :cascade
    end
  end
end
