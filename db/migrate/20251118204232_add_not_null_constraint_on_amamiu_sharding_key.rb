# frozen_string_literal: true

class AddNotNullConstraintOnAmamiuShardingKey < Gitlab::Database::Migration[2.3]
  # NOTE: Shortening the file name per Cop/FilenameLength: This file name is too long. It should be 100 or less
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_not_null_constraint(:alert_management_alert_metric_image_uploads, :project_id)
  end

  def down
    remove_not_null_constraint(:alert_management_alert_metric_image_uploads, :project_id)
  end
end
