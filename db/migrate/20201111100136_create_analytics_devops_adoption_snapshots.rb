# frozen_string_literal: true

class CreateAnalyticsDevopsAdoptionSnapshots < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :analytics_devops_adoption_snapshots do |t|
      t.references :segment, index: false, null: false, foreign_key: { to_table: :analytics_devops_adoption_segments, on_delete: :cascade }
      t.datetime_with_timezone :recorded_at, null: false
      t.boolean :issue_opened, null: false
      t.boolean :merge_request_opened, null: false
      t.boolean :merge_request_approved, null: false
      t.boolean :runner_configured, null: false
      t.boolean :pipeline_succeeded, null: false
      t.boolean :deploy_succeeded, null: false
      t.boolean :security_scan_succeeded, null: false

      t.index [:segment_id, :recorded_at], name: 'index_on_snapshots_segment_id_recorded_at'
    end
  end
end
