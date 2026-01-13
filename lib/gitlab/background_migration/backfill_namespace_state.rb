# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Metrics/ClassLength -- Backfilling from multiple sources increases the length
    class BackfillNamespaceState < BatchedMigrationJob
      operation_name :backfill_namespace_state
      feature_category :groups_and_projects

      # State values matching Namespaces::Stateful::STATES
      STATES = {
        ancestor_inherited: nil,
        archived: 1,
        deletion_scheduled: 2,
        deletion_in_progress: 4
      }.freeze

      PRESERVE_EVENTS = {
        deletion_scheduled: 'schedule_deletion',
        deletion_in_progress: 'start_deletion'
      }.freeze

      def perform
        each_sub_batch do |sub_batch|
          namespace_ids = sub_batch.pluck(:id)
          backfill_namespace_state_and_metadata(namespace_ids.join(','))
        end
      end

      private

      # rubocop:disable Metrics/MethodLength -- Need to do atomic updates
      def backfill_namespace_state_and_metadata(ids_list)
        start_deletion_event = PRESERVE_EVENTS[:deletion_in_progress]
        schedule_deletion_event = PRESERVE_EVENTS[:deletion_scheduled]

        connection.execute(<<~SQL)
          WITH state_indicators AS (
            SELECT
              n.id AS namespace_id,
              n.state AS current_state,
              -- Deletion in progress indicators
              nd.deleted_at IS NOT NULL AS group_deletion_in_progress,
              p_pending.id IS NOT NULL AS project_deletion_in_progress,
              -- Deletion scheduled indicators and metadata
              gds.group_id IS NOT NULL AS group_deletion_scheduled,
              gds.marked_for_deletion_on AS group_marked_on,
              gds.user_id AS group_scheduled_by,
              p_marked.id IS NOT NULL AS project_deletion_scheduled,
              p_marked.marked_for_deletion_at AS project_marked_at,
              p_marked.marked_for_deletion_by_user_id AS project_scheduled_by,
              p_marked.delete_error AS project_delete_error,
              -- Archived indicators
              ns.archived = TRUE AS group_archived,
              p_archived.id IS NOT NULL AS project_archived,
              -- Existing metadata
              nd_meta.state_metadata AS existing_metadata
            FROM namespaces n
            LEFT JOIN namespace_details nd ON nd.namespace_id = n.id AND nd.deleted_at IS NOT NULL
            LEFT JOIN projects p_pending ON p_pending.project_namespace_id = n.id AND p_pending.pending_delete = TRUE
            LEFT JOIN group_deletion_schedules gds ON gds.group_id = n.id
            LEFT JOIN projects p_marked ON p_marked.project_namespace_id = n.id AND p_marked.marked_for_deletion_at IS NOT NULL
            LEFT JOIN namespace_settings ns ON ns.namespace_id = n.id AND ns.archived = TRUE
            LEFT JOIN projects p_archived ON p_archived.project_namespace_id = n.id AND p_archived.archived = TRUE
            LEFT JOIN namespace_details nd_meta ON nd_meta.namespace_id = n.id
            WHERE n.id IN (#{ids_list})
          ),
          computed_updates AS (
            SELECT
              si.namespace_id,
              si.current_state,
              si.existing_metadata,
              -- Derived boolean flags
              (si.group_deletion_in_progress OR si.project_deletion_in_progress) AS has_deletion_in_progress,
              (si.group_deletion_scheduled OR si.project_deletion_scheduled) AS has_deletion_scheduled,
              (si.group_archived OR si.project_archived) AS has_archived,
              -- Compute expected state based on priority
              CASE
                WHEN si.group_deletion_in_progress OR si.project_deletion_in_progress THEN #{STATES[:deletion_in_progress]}
                WHEN si.group_deletion_scheduled OR si.project_deletion_scheduled THEN #{STATES[:deletion_scheduled]}
                WHEN si.group_archived OR si.project_archived THEN #{STATES[:archived]}
              END AS expected_state,
              -- Deletion scheduled metadata (prefer group over project)
              CASE
                WHEN si.group_marked_on IS NOT NULL THEN
                  jsonb_build_object(
                    'deletion_scheduled_at', to_char(si.group_marked_on, 'YYYY-MM-DD"T"00:00:00"Z"'),
                    'deletion_scheduled_by_user_id', si.group_scheduled_by
                  )
                WHEN si.project_marked_at IS NOT NULL THEN
                  jsonb_strip_nulls(jsonb_build_object(
                    'deletion_scheduled_at', to_char(si.project_marked_at, 'YYYY-MM-DD"T"00:00:00"Z"'),
                    'deletion_scheduled_by_user_id', si.project_scheduled_by,
                    'last_error', si.project_delete_error
                  ))
                ELSE '{}'::jsonb
              END AS deletion_metadata
            FROM state_indicators si
            WHERE si.group_deletion_in_progress OR si.project_deletion_in_progress
               OR si.group_deletion_scheduled OR si.project_deletion_scheduled
               OR si.group_archived OR si.project_archived
          ),
          final_updates AS (
            SELECT
              cu.namespace_id,
              cu.current_state,
              cu.expected_state,
              -- Combine deletion metadata with preserved states
              cu.deletion_metadata || CASE
                -- deletion_in_progress + deletion_scheduled + archived
                WHEN cu.has_deletion_in_progress AND cu.has_deletion_scheduled AND cu.has_archived THEN
                  jsonb_build_object('preserved_states', jsonb_build_object(
                    '#{start_deletion_event}', 'deletion_scheduled',
                    '#{schedule_deletion_event}', 'archived'
                  ))
                -- deletion_in_progress + deletion_scheduled
                WHEN cu.has_deletion_in_progress AND cu.has_deletion_scheduled THEN
                  jsonb_build_object('preserved_states', jsonb_build_object(
                    '#{start_deletion_event}', 'deletion_scheduled'
                  ))
                -- deletion_in_progress + archived
                WHEN cu.has_deletion_in_progress AND cu.has_archived THEN
                  jsonb_build_object('preserved_states', jsonb_build_object(
                    '#{start_deletion_event}', 'archived'
                  ))
                -- deletion_in_progress only
                WHEN cu.has_deletion_in_progress THEN
                  jsonb_build_object('preserved_states', jsonb_build_object(
                    '#{start_deletion_event}', 'ancestor_inherited'
                  ))
                -- deletion_scheduled + archived
                WHEN cu.has_deletion_scheduled AND cu.has_archived THEN
                  jsonb_build_object('preserved_states', jsonb_build_object(
                    '#{schedule_deletion_event}', 'archived'
                  ))
                -- deletion_scheduled only
                WHEN cu.has_deletion_scheduled THEN
                  jsonb_build_object('preserved_states', jsonb_build_object(
                    '#{schedule_deletion_event}', 'ancestor_inherited'
                  ))
                ELSE '{}'::jsonb
              END AS metadata,
              -- Check if metadata needs backfilling
              cu.existing_metadata IS NULL
                OR NOT cu.existing_metadata ? 'preserved_states'
                OR (cu.has_deletion_scheduled AND NOT cu.existing_metadata ? 'deletion_scheduled_at')
              AS needs_metadata_backfill
            FROM computed_updates cu
          ),
          -- Update namespaces.state only if state is NULL
          namespace_state_updates AS (
            UPDATE namespaces
            SET state = fu.expected_state
            FROM final_updates fu
            WHERE namespaces.id = fu.namespace_id
              AND fu.expected_state IS NOT NULL
              AND namespaces.state IS NULL
            RETURNING namespaces.id
          ),
          -- Collect all namespace IDs that need metadata updates
          -- (either state was just updated OR metadata needs backfilling)
          namespaces_needing_metadata AS (
            SELECT fu.namespace_id, fu.metadata
            FROM final_updates fu
            WHERE fu.metadata != '{}'::jsonb
              AND (
                -- State was NULL and just got updated
                fu.current_state IS NULL
                -- OR state was already set but metadata is missing
                OR fu.needs_metadata_backfill
              )
          )
          INSERT INTO namespace_details (namespace_id, state_metadata, created_at, updated_at)
          SELECT
            nm.namespace_id,
            nm.metadata,
            NOW(),
            NOW()
          FROM namespaces_needing_metadata nm
          ON CONFLICT (namespace_id) DO UPDATE
          SET state_metadata = namespace_details.state_metadata || EXCLUDED.state_metadata,
              updated_at = NOW()
        SQL
      end
      # rubocop:enable Metrics/MethodLength
    end
    # rubocop:enable Metrics/ClassLength
  end
end
