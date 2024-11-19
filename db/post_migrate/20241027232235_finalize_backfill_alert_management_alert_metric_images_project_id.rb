# frozen_string_literal: true

class FinalizeBackfillAlertManagementAlertMetricImagesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillAlertManagementAlertMetricImagesProjectId',
      table_name: :alert_management_alert_metric_images,
      column_name: :id,
      job_arguments: [:project_id, :alert_management_alerts, :project_id, :alert_id],
      finalize: true
    )
  end

  def down; end
end
