# frozen_string_literal: true

class BackfillCreatedByDuoOnMergeRequests < ClickHouse::Migration
  BATCH_SIZE = 100_000

  # merge_requests is replicated by Siphon, so it must not be mutated in place.
  # Reinserting the rows into siphon_merge_requests (Null engine) re-triggers the
  # merge_requests MVs, which recompute created_by_duo.
  def up
    columns = siphon_merge_requests_columns
    builder = ClickHouse::Client::QueryBuilder.new('siphon_duo_workflows_workflow_merge_requests')
    iterator = ClickHouse::Iterator.new(query_builder: builder, connection: connection)

    iterator.each_batch(column: :id, of: BATCH_SIZE) do |scope|
      merge_request_ids = scope.select(:merge_request_id).where(link_type: 1)

      execute(<<~SQL)
        INSERT INTO siphon_merge_requests (#{columns.join(', ')})
        SELECT #{select_list(columns)}
        FROM merge_requests
        WHERE id IN (#{merge_request_ids.to_sql})
      SQL
    end
  end

  def down
    # no-op: the column is dropped by AddCreatedByDuoToMergeRequests#down
  end

  private

  def siphon_merge_requests_columns
    connection.select(<<~SQL).pluck('name')
      SELECT name
      FROM system.columns
      WHERE database = currentDatabase()
        AND table = 'siphon_merge_requests'
      ORDER BY position
    SQL
  end

  # +1us so the reinserted version wins over the current one in ReplacingMergeTree,
  # while any later Siphon change still wins over the reinserted one.
  def select_list(columns)
    columns.map do |column|
      if column == '_siphon_replicated_at'
        'addMicroseconds(merge_requests._siphon_replicated_at, 1) AS _siphon_replicated_at'
      else
        column
      end
    end.join(', ')
  end
end
