# frozen_string_literal: true

class AddIndexOnProjectSettingsForOldPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX = 'index_project_ci_cd_settings_on_id_partial'

  def up
    add_concurrent_index :project_ci_cd_settings, :id,
      where: 'delete_pipelines_in_seconds IS NOT NULL', name: INDEX
  end

  def down
    remove_concurrent_index :project_ci_cd_settings, :id, name: INDEX
  end
end
