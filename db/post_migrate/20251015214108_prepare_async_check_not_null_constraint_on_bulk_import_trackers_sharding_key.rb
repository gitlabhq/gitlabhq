# frozen_string_literal: true

class PrepareAsyncCheckNotNullConstraintOnBulkImportTrackersShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_5f034e7cad'

  def up
    prepare_async_check_constraint_validation :bulk_import_trackers, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :bulk_import_trackers, name: CONSTRAINT_NAME
  end
end
