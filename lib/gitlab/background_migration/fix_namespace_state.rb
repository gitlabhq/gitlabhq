# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Metrics/ClassLength -- Backfilling from multiple sources increases the length
    class FixNamespaceState < BatchedMigrationJob
      operation_name :fix_namespace_state
      feature_category :groups_and_projects

      # Subset of namespace state enum values used by this migration (archive/deletion related only)
      STATES = {
        ancestor_inherited: 0,
        archived: 1,
        deletion_scheduled: 2,
        deletion_in_progress: 4
      }.freeze

      PRESERVE_EVENTS = {
        deletion_scheduled: 'schedule_deletion'
      }.freeze

      def perform
        each_sub_batch do |sub_batch|
          namespace_ids = sub_batch.pluck(:id)
          fix_namespace_state_and_metadata(namespace_ids.join(','))
        end
      end

      private

      # rubocop:disable Metrics/MethodLength -- Need to do atomic updates
      def fix_namespace_state_and_metadata(ids_list)
        schedule_deletion_event = PRESERVE_EVENTS[:deletion_scheduled]

        connection.execute(<<~SQL)
          WITH state_indicators AS (
            SELECT
              n.id AS namespace_id,
              n.state AS current_state,
              -- Deletion scheduled indicators and metadata
              gds.group_id IS NOT NULL AS group_deletion_scheduled,
              gds.marked_for_deletion_on AS group_marked_on,
              gds.user_id AS group_scheduled_by,
              p.marked_for_deletion_at IS NOT NULL AS project_deletion_scheduled,
              p.marked_for_deletion_at AS project_marked_at,
              p.marked_for_deletion_by_user_id AS project_scheduled_by,
              -- Archived indicators
              ns.archived = TRUE AS group_archived,
              p.archived IS TRUE AS project_archived,
              -- Existing metadata
              nd_meta.state_metadata AS existing_metadata,
              nd_meta.deletion_scheduled_at AS existing_deletion_scheduled_at
            FROM namespaces n
            LEFT JOIN group_deletion_schedules gds ON gds.group_id = n.id AND n.type = 'Group'
            LEFT JOIN projects p ON p.project_namespace_id = n.id AND n.type = 'Project'
            LEFT JOIN namespace_settings ns ON ns.namespace_id = n.id AND ns.archived = TRUE
            LEFT JOIN namespace_details nd_meta ON nd_meta.namespace_id = n.id
            WHERE n.id IN (#{ids_list})
          ),
          computed_updates AS (
            SELECT
              si.namespace_id,
              si.current_state,
              si.existing_metadata,
              si.existing_deletion_scheduled_at,
              -- Derived boolean flags
              (si.group_deletion_scheduled OR si.project_deletion_scheduled) AS has_deletion_scheduled,
              (si.group_archived OR si.project_archived) AS has_archived,
              -- Compute expected state based on priority
              CASE
                WHEN si.group_deletion_scheduled OR si.project_deletion_scheduled THEN #{STATES[:deletion_scheduled]}
                WHEN si.group_archived OR si.project_archived THEN #{STATES[:archived]}
                ELSE #{STATES[:ancestor_inherited]}
              END AS expected_state,
              -- Deletion scheduled timestamp (group and project are mutually exclusive)
              CASE
                WHEN si.group_marked_on IS NOT NULL THEN si.group_marked_on::timestamptz
                WHEN si.project_marked_at IS NOT NULL THEN si.project_marked_at::timestamptz
              END AS computed_deletion_scheduled_at,
              -- Deletion scheduled metadata (group and project are mutually exclusive)
              CASE
                WHEN si.group_scheduled_by IS NOT NULL THEN
                  jsonb_build_object('deletion_scheduled_by_user_id', si.group_scheduled_by)
                WHEN si.project_scheduled_by IS NOT NULL THEN
                  jsonb_build_object('deletion_scheduled_by_user_id', si.project_scheduled_by)
                ELSE '{}'::jsonb
              END AS deletion_metadata
            FROM state_indicators si
          ),
          final_updates AS (
            SELECT
              cu.namespace_id,
              cu.current_state,
              cu.expected_state,
              cu.computed_deletion_scheduled_at,
              -- Compute the complete desired state_metadata based on expected state:
              -- deletion_scheduled: merge new deletion metadata into existing metadata.
              -- archived/ancestor_inherited: strip deletion-related keys from existing metadata.
              CASE
                WHEN cu.expected_state = #{STATES[:deletion_scheduled]} THEN
                  cu.existing_metadata || cu.deletion_metadata || CASE
                    WHEN cu.has_archived THEN
                      jsonb_build_object('preserved_states', jsonb_build_object(
                        '#{schedule_deletion_event}', 'archived'
                      ))
                    ELSE
                      jsonb_build_object('preserved_states', jsonb_build_object(
                        '#{schedule_deletion_event}', 'ancestor_inherited'
                      ))
                  END
                WHEN cu.expected_state = #{STATES[:archived]} THEN
                  cu.existing_metadata - 'deletion_scheduled_by_user_id' - 'preserved_states'
                ELSE '{}'::jsonb
              END AS final_metadata,
              -- Compute final deletion_scheduled_at:
              -- Only set for deletion_scheduled state; clear for all others.
              CASE
                WHEN cu.expected_state = #{STATES[:deletion_scheduled]} THEN
                  COALESCE(cu.computed_deletion_scheduled_at, cu.existing_deletion_scheduled_at)
                ELSE NULL
              END AS final_deletion_scheduled_at
            FROM computed_updates cu
            WHERE (
              -- State is NULL (not yet backfilled)
              cu.current_state IS NULL
              -- State is 0 but may need fixing
              OR cu.current_state = #{STATES[:ancestor_inherited]}
              -- State doesn't match what attributes indicate
              OR cu.current_state != cu.expected_state
              -- State matches but metadata needs backfilling
              OR (
                cu.current_state = cu.expected_state
                AND cu.expected_state != #{STATES[:ancestor_inherited]}
                AND (
                  cu.existing_metadata = '{}'::jsonb
                  OR NOT cu.existing_metadata ? 'preserved_states'
                  OR (cu.has_deletion_scheduled AND cu.existing_deletion_scheduled_at IS NULL)
                )
              )
            )
            -- Skip deletion_in_progress — already managed by the state machine.
            -- COALESCE handles NULL state so it isn't incorrectly excluded.
            AND COALESCE(cu.current_state, -1) != #{STATES[:deletion_in_progress]}
          ),
          -- Update namespaces.state when it differs from the expected state
          namespace_state_updates AS (
            UPDATE namespaces
            SET state = fu.expected_state,
                updated_at = NOW()
            FROM final_updates fu
            WHERE namespaces.id = fu.namespace_id
              AND namespaces.state IS DISTINCT FROM fu.expected_state
            RETURNING namespaces.id
          )
          -- Upsert namespace_details with computed metadata and deletion_scheduled_at.
          -- ancestor_inherited: clears all metadata.
          -- archived: strips deletion-related keys, clears deletion_scheduled_at.
          -- deletion_scheduled: merges deletion metadata into existing, sets deletion_scheduled_at.
          INSERT INTO namespace_details (namespace_id, state_metadata, deletion_scheduled_at, created_at, updated_at)
          SELECT
            fu.namespace_id,
            fu.final_metadata,
            fu.final_deletion_scheduled_at,
            NOW(),
            NOW()
          FROM final_updates fu
          ON CONFLICT (namespace_id) DO UPDATE
          SET state_metadata = EXCLUDED.state_metadata,
              deletion_scheduled_at = EXCLUDED.deletion_scheduled_at,
              updated_at = NOW()
        SQL
      end
      # rubocop:enable Metrics/MethodLength
    end
    # rubocop:enable Metrics/ClassLength
  end
end
