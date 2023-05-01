# frozen_string_literal: true

class AddPartitionedVsdCountsTable < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    execute(<<~SQL)
      CREATE TABLE value_stream_dashboard_counts (
        id bigserial NOT NULL,
        namespace_id bigint NOT NULL,
        count bigint NOT NULL,
        recorded_at timestamp with time zone NOT NULL,
        metric smallint NOT NULL,
        PRIMARY KEY (namespace_id, metric, recorded_at, count, id)
      ) PARTITION BY RANGE (recorded_at);
    SQL

    min_date = Date.today
    max_date = Date.today + 6.months
    create_daterange_partitions('value_stream_dashboard_counts', 'recorded_at', min_date, max_date)
  end

  def down
    drop_table :value_stream_dashboard_counts
  end
end
