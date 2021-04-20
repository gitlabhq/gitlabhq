# frozen_string_literal: true

class AddIndexToPagesDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_pages_deployments_on_file_store_and_id'

  def up
    add_concurrent_index :pages_deployments, [:file_store, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :pages_deployments, INDEX_NAME
  end
end
