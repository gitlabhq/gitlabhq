# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateDuoSecretDetectionFpEnabledToFalse < BatchedMigrationJob
      cursor :project_id
      operation_name :update_all
      feature_category :vulnerability_management

      # The 18.11 post-deploy migration that flipped the column default to false. Its
      # schema_migrations.finished_at is the per-instance instant the default became false (see #cutoff).
      DEFAULT_FLIP_MIGRATION_VERSION = '20260408120000'

      # Fallback cutoff (the gitlab.com flip instant, per deployment note MR 230614), used only when
      # the schema_migrations row above is absent or NULL. +01:00 (BST) pins the instant across timezones.
      DEFAULT_CHANGED_AT = '2026-04-13 07:44:00+01:00'

      # The foundational flow whose deliberate enablement we must not undo.
      FOUNDATIONAL_FLOW_REFERENCE = 'secrets_fp_detection/v1'

      # We reset the accidental default unless the secret-FP foundational flow is enabled,
      # read from the MATERIALISED enabled_foundational_flows rows on the project itself - NOT
      # the authoritative project->ancestor recursion. Enabling the flow at a group cascades a
      # per-project row to every descendant project, so a project-level row is present for genuine
      # opt-ins; we deliberately accept missing the rare project whose cascade is stale (transfer
      # or async lag), a ~1% gap traded for a single-table, index-only check.
      UPDATE_SQL = <<~SQL.freeze
        WITH batch AS MATERIALIZED (
          %{project_ids}
        ),
        fp_items AS MATERIALIZED (
          SELECT id FROM ai_catalog_items
          WHERE foundational_flow_reference = '#{FOUNDATIONAL_FLOW_REFERENCE}'
            AND deleted_at IS NULL
        )
        UPDATE project_settings ps
        SET duo_secret_detection_fp_enabled = FALSE
        WHERE ps.project_id IN (SELECT project_id FROM batch)
          AND ps.duo_secret_detection_fp_enabled = TRUE
          AND ps.created_at < %{cutoff}
          AND NOT EXISTS (
            SELECT 1
            FROM enabled_foundational_flows efp
            WHERE efp.project_id = ps.project_id
              AND efp.catalog_item_id IN (SELECT id FROM fp_items)
          )
      SQL

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            format(
              UPDATE_SQL,
              project_ids: sub_batch.select(:project_id).limit(sub_batch_size).to_sql,
              cutoff: cutoff
            )
          )
        end
      end

      private

      # Per-instance default-flip instant (schema_migrations.finished_at), else DEFAULT_CHANGED_AT.
      # Memoised; returns an already-quoted SQL literal, so UPDATE_SQL omits surrounding quotes.
      def cutoff
        @cutoff ||= begin
          version = connection.quote(DEFAULT_FLIP_MIGRATION_VERSION)
          finished_at = connection.select_value(
            "SELECT finished_at FROM schema_migrations WHERE version = #{version}"
          )

          connection.quote(finished_at || DEFAULT_CHANGED_AT)
        end
      end
    end
  end
end
