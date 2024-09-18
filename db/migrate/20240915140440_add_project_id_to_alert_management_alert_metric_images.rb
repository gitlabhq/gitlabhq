# frozen_string_literal: true

class AddProjectIdToAlertManagementAlertMetricImages < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :alert_management_alert_metric_images, :project_id, :bigint
  end
end
