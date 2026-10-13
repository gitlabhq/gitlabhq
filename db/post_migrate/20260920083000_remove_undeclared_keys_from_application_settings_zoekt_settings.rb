# frozen_string_literal: true

class RemoveUndeclaredKeysFromApplicationSettingsZoektSettings < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting
  milestone '19.5'

  # Frozen copy, not a live schema read: that would retroactively change what past runs removed.
  DECLARED_KEYS = %w[
    zoekt_auto_delete_lost_nodes zoekt_auto_index_root_namespace zoekt_cache_response zoekt_cpu_to_tasks_ratio
    zoekt_default_number_of_replicas zoekt_force_reindexing_percentage zoekt_indexed_file_size_limit
    zoekt_indexing_enabled zoekt_indexing_parallelism zoekt_indexing_paused zoekt_indexing_timeout
    zoekt_lost_node_threshold zoekt_max_projects_for_legacy_search zoekt_max_restarts_15m zoekt_maximum_files
    zoekt_rollout_batch_size zoekt_rollout_retry_interval zoekt_search_enabled zoekt_trigram_max
  ].freeze

  def up
    declared = connection.quote(DECLARED_KEYS.join(','))

    # jsonb_each raises on a non-object, aborting the upgrade; such a row cannot be repaired here.
    execute(<<~SQL)
      UPDATE application_settings
      SET zoekt_settings = zoekt_settings - ARRAY(
        SELECT key FROM jsonb_each(zoekt_settings)
        WHERE key <> ALL (string_to_array(#{declared}, ','))
      )
      WHERE jsonb_typeof(zoekt_settings) = 'object'
        AND EXISTS (
          SELECT 1 FROM jsonb_each(zoekt_settings)
          WHERE key <> ALL (string_to_array(#{declared}, ','))
        )
    SQL
  end

  def down
    # Undeclared keys are unread, so their values cannot be reconstructed. Rollback is a no-op.
  end
end
