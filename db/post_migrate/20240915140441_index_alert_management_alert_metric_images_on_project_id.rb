# frozen_string_literal: true

class IndexAlertManagementAlertMetricImagesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_alert_management_alert_metric_images_on_project_id'

  def up
    add_concurrent_index :alert_management_alert_metric_images, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :alert_management_alert_metric_images, INDEX_NAME
  end
end
