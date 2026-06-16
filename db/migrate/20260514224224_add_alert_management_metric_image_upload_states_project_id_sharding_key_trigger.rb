# frozen_string_literal: true

class AddAlertManagementMetricImageUploadStatesProjectIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :alert_management_metric_image_upload_states,
      sharding_key: :project_id,
      parent_table: :alert_management_alert_metric_image_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :alert_management_metric_image_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :alert_management_metric_image_upload_states,
      sharding_key: :project_id,
      parent_table: :alert_management_alert_metric_image_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :alert_management_metric_image_upload_id
    )
  end
end
