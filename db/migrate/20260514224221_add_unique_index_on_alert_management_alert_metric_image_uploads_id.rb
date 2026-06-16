# frozen_string_literal: true

class AddUniqueIndexOnAlertManagementAlertMetricImageUploadsId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  PARTITION_TABLE_NAME = :alert_management_alert_metric_image_uploads
  PARTITION_INDEX_NAME = :idx_alert_management_alert_metric_image_uploads_on_id

  def up
    add_concurrent_index PARTITION_TABLE_NAME, :id, unique: true, name: PARTITION_INDEX_NAME, allow_partition: true
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{PARTITION_INDEX_NAME}"
  end
end
