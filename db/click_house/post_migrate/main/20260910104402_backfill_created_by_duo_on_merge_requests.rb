# frozen_string_literal: true

class BackfillCreatedByDuoOnMergeRequests < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE merge_requests
      UPDATE created_by_duo = true
      WHERE created_by_duo = false AND id IN (
        SELECT merge_request_id
        FROM (
          SELECT
            id,
            argMax(merge_request_id, _siphon_replicated_at) AS merge_request_id,
            argMax(link_type, _siphon_replicated_at) AS link_type,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_duo_workflows_workflow_merge_requests
          GROUP BY id
        )
        WHERE link_type = 1 AND deleted = false
      )
    SQL
  end

  def down
    # no-op: the column is dropped by AddCreatedByDuoToMergeRequests#down
  end
end
