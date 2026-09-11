# frozen_string_literal: true

class AddMergeRequestIdProjectionToSiphonDuoWorkflowsWorkflowMergeRequests < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflow_merge_requests
      MODIFY SETTING deduplicate_merge_projection_mode = 'rebuild'
    SQL

    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflow_merge_requests
        ADD PROJECTION IF NOT EXISTS by_merge_request_id
        (
          SELECT
            id,
            workflow_id,
            merge_request_id,
            link_type,
            traversal_path,
            _siphon_replicated_at,
            _siphon_deleted
          ORDER BY
            merge_request_id,
            id
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflow_merge_requests MATERIALIZE PROJECTION by_merge_request_id
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflow_merge_requests DROP PROJECTION IF EXISTS by_merge_request_id
      SETTINGS mutations_sync = 0
    SQL
  end
end
