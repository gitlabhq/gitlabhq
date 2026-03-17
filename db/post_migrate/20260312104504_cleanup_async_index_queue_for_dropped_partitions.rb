# frozen_string_literal: true

class CleanupAsyncIndexQueueForDroppedPartitions < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  ORPHANED_TABLE_NAMES = [
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260113',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260114',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260115',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260116',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260117',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260118',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260119',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260120',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260121',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260122',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260123',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260124',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260125',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260126',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260127',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260128',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20260129'
  ].freeze

  def up
    quoted_values = ORPHANED_TABLE_NAMES.map { |name| connection.quote(name) }.join(', ')

    execute <<~SQL
      DELETE FROM postgres_async_indexes WHERE table_name IN (#{quoted_values})
    SQL
  end

  def down
    # no-op: we don't want to restore orphaned records
  end
end
