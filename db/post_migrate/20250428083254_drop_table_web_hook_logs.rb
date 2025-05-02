# frozen_string_literal: true

class DropTableWebHookLogs < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.0'

  NEW_TABLE_NAME = :web_hook_logs_daily
  OLD_TABLE_NAME = :web_hook_logs
  INDEX_NAME_1 = :index_web_hook_logs_on_web_hook_id_and_created_at
  INDEX_NAME_2 = :index_web_hook_logs_part_on_created_at_and_web_hook_id

  def up
    drop_table(:web_hook_logs)
  end

  def down
    transaction do
      execute(<<~SQL)
        CREATE TABLE #{OLD_TABLE_NAME} (
          LIKE #{NEW_TABLE_NAME} INCLUDING ALL EXCLUDING INDEXES,
          PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE (created_at);

        CREATE TABLE IF NOT EXISTS #{partition_name(nil)}
          PARTITION OF #{OLD_TABLE_NAME}
          FOR VALUES FROM (MINVALUE) TO (\'#{current_date.prev_month.beginning_of_month}\');

        CREATE TABLE IF NOT EXISTS #{partition_name(current_date.prev_month)}
          PARTITION OF #{OLD_TABLE_NAME}
          FOR VALUES FROM (\'#{current_date.prev_month.beginning_of_month}\') TO (\'#{current_date.prev_month.end_of_month}\');

        CREATE TABLE IF NOT EXISTS #{partition_name(current_date)}
          PARTITION OF #{OLD_TABLE_NAME}
          FOR VALUES FROM (\'#{current_date.beginning_of_month}\') TO (\'#{current_date.end_of_month}\');

        CREATE TABLE IF NOT EXISTS #{partition_name(current_date.next_month)}
          PARTITION OF #{OLD_TABLE_NAME}
          FOR VALUES FROM (\'#{current_date.next_month.beginning_of_month}\') TO (\'#{current_date.next_month.end_of_month}\')
      SQL
    end

    add_concurrent_partitioned_index(OLD_TABLE_NAME, [:web_hook_id, :created_at], name: INDEX_NAME_1)
    add_concurrent_partitioned_index(OLD_TABLE_NAME, [:created_at, :web_hook_id], name: INDEX_NAME_2)
  end

  private

  def current_date
    Date.current
  end

  def partition_name(date)
    suffix = date&.strftime('%Y%m') || '000000'
    "gitlab_partitions_dynamic.#{OLD_TABLE_NAME}_#{suffix}"
  end
end
