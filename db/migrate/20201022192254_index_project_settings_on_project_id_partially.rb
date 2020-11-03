# frozen_string_literal: true

class IndexProjectSettingsOnProjectIdPartially < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_project_settings_on_project_id_partially'

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_settings, :project_id, name: INDEX_NAME, where: 'has_vulnerabilities IS TRUE'
  end

  def down
    remove_concurrent_index_by_name :project_settings, INDEX_NAME
  end
end
