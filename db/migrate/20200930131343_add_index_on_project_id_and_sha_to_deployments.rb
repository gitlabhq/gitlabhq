# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexOnProjectIdAndShaToDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  INDEX_NAME = 'index_deployments_on_project_id_sha'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :sha], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:deployments, INDEX_NAME)
  end
end
