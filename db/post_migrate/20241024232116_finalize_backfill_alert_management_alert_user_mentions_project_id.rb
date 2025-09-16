# frozen_string_literal: true

class FinalizeBackfillAlertManagementAlertUserMentionsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillAlertManagementAlertUserMentionsProjectId',
      table_name: :alert_management_alert_user_mentions,
      column_name: :id,
      job_arguments: [:project_id, :alert_management_alerts, :project_id, :alert_management_alert_id],
      finalize: true
    )
  end

  def down; end
end
