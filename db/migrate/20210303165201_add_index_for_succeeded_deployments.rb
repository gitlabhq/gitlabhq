# frozen_string_literal: true

class AddIndexForSucceededDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_deployments_on_environment_id_status_and_finished_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:deployments, %i[environment_id status finished_at], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:deployments, INDEX_NAME)
  end
end
