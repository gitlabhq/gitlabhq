# frozen_string_literal: true

class IndexProjectCiCdSettingsForPipelineRemoval < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  OLD_INDEX = 'index_project_ci_cd_settings_on_id_partial'
  INDEX = 'index_project_ci_cd_settings_on_project_id_partial'

  def up
    remove_concurrent_index :project_ci_cd_settings, :id, name: OLD_INDEX
    add_concurrent_index :project_ci_cd_settings, :project_id,
      where: 'delete_pipelines_in_seconds IS NOT NULL', name: INDEX
  end

  def down
    add_concurrent_index :project_ci_cd_settings, :id,
      where: 'delete_pipelines_in_seconds IS NOT NULL', name: OLD_INDEX
    remove_concurrent_index :project_ci_cd_settings, :project_id, name: INDEX
  end
end
