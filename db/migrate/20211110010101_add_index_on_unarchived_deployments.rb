# frozen_string_literal: true

class AddIndexOnUnarchivedDeployments < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_deployments_on_archived_project_id_iid'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, %i[archived project_id iid], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deployments, INDEX_NAME
  end
end
