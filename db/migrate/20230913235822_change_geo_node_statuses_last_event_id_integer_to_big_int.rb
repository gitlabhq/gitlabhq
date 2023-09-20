# frozen_string_literal: true

class ChangeGeoNodeStatusesLastEventIdIntegerToBigInt < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute "ALTER TABLE geo_node_statuses ALTER COLUMN last_event_id TYPE bigint;"
    end

    execute "ANALYZE geo_node_statuses;"
  end

  def down
    with_lock_retries do
      execute "ALTER TABLE geo_node_statuses ALTER COLUMN last_event_id TYPE integer;"
    end

    execute "ANALYZE geo_node_statuses;"
  end
end
