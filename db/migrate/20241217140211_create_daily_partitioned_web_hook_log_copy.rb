# frozen_string_literal: true

class CreateDailyPartitionedWebHookLogCopy < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  TABLE_NAME = :web_hook_logs_daily
  SOURCE_TABLE_NAME = :web_hook_logs

  def up
    transaction do
      execute(<<~SQL)
        CREATE TABLE #{TABLE_NAME} (
          LIKE #{SOURCE_TABLE_NAME} INCLUDING ALL EXCLUDING INDEXES,
          PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE (created_at);

        CREATE TABLE IF NOT EXISTS #{partition_name(nil)}
          PARTITION OF #{TABLE_NAME}
          FOR VALUES FROM (MINVALUE) TO (\'#{current_date.prev_day}\');

        CREATE TABLE IF NOT EXISTS #{partition_name(current_date.prev_day)}
          PARTITION OF #{TABLE_NAME}
          FOR VALUES FROM (\'#{current_date.prev_day}\') TO (\'#{current_date}\');

        CREATE TABLE IF NOT EXISTS #{partition_name(current_date)}
          PARTITION OF #{TABLE_NAME}
          FOR VALUES FROM (\'#{current_date}\') TO (\'#{current_date.next_day}\');

        CREATE TABLE IF NOT EXISTS #{partition_name(current_date.next_day)}
          PARTITION OF #{TABLE_NAME}
          FOR VALUES FROM (\'#{current_date.next_day}\') TO (\'#{current_date.next_day.next_day}\')
      SQL
    end
  end

  def down
    execute(<<~SQL)
      DROP TABLE #{TABLE_NAME}
    SQL
  end

  private

  def current_date
    Date.current
  end

  def partition_name(date)
    suffix = date&.strftime('%Y%m%d') || '00000000'
    "gitlab_partitions_dynamic.#{TABLE_NAME}_#{suffix}"
  end
end
