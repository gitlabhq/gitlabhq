# frozen_string_literal: true

class AddAllowStaleRunnerPruningIndexToNamespaceCiCdSettings < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_cicd_settings_on_namespace_id_where_stale_pruning_enabled'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespace_ci_cd_settings,
      :namespace_id,
      where: '(allow_stale_runner_pruning = true)',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespace_ci_cd_settings, INDEX_NAME
  end
end
