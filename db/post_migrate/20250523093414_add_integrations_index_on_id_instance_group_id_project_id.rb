# frozen_string_literal: true

class AddIntegrationsIndexOnIdInstanceGroupIdProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_integrations_on_id_instance_group_id_project_id'

  def up
    add_concurrent_index(
      :integrations,
      :id,
      where: 'instance = FALSE AND group_id IS NULL AND project_id IS NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end
end
