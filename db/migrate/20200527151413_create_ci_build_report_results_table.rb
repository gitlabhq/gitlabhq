# frozen_string_literal: true

class CreateCiBuildReportResultsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :ci_build_report_results, id: false do |t|
      t.bigint :build_id, null: false, index: false, primary_key: true
      t.bigint :project_id, null: false, index: true
      t.jsonb :data, null: false, default: {}
    end
  end
end
