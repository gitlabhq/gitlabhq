# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateMetricsDashboardAnnotations < ActiveRecord::Migration[6.0]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :metrics_dashboard_annotations do |t|
      t.datetime_with_timezone :starting_at, null: false
      t.datetime_with_timezone :ending_at
      t.references :environment, index: false, foreign_key: { on_delete: :cascade }, null: true
      t.references :cluster, index: false, foreign_key: { on_delete: :cascade }, null: true
      t.string :dashboard_path, null: false, limit: 255
      t.string :panel_xid, limit: 255
      t.text :description, null: false, limit: 255 # rubocop:disable Migration/AddLimitToTextColumns

      t.index %i(environment_id dashboard_path starting_at ending_at), where: 'environment_id IS NOT NULL', name: "index_metrics_dashboard_annotations_on_environment_id_and_3_col"
      t.index %i(cluster_id dashboard_path starting_at ending_at), where: 'cluster_id IS NOT NULL', name: "index_metrics_dashboard_annotations_on_cluster_id_and_3_columns"
    end
  end
  # rubocop:enable Migration/PreventStrings
end
