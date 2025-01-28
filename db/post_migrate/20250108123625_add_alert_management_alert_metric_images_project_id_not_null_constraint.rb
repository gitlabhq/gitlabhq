# frozen_string_literal: true

class AddAlertManagementAlertMetricImagesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :alert_management_alert_metric_images, :project_id
  end

  def down
    remove_not_null_constraint :alert_management_alert_metric_images, :project_id
  end
end
