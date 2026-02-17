# frozen_string_literal: true

class CleanupPostgresAsyncQueue < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  ORPHANED_TABLE_NAMES = [
    'gitlab_partitions_dynamic.web_hook_logs_daily_20251223',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20251224',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20251225',
    'gitlab_partitions_dynamic.web_hook_logs_daily_20251226'
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
