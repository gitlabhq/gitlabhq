# frozen_string_literal: true

class AddIndexProjectIdAndIdToContainerRepositories < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_container_repositories_on_project_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:container_repositories, [:project_id, :id], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:container_repositories, [:project_id, :id], name: INDEX_NAME)
  end
end
