# frozen_string_literal: true

class IndexOnIntegrationTypeNewIdWhenActiveAndHasGroup < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_integrations_on_type_new_id_when_active_and_has_group'

  disable_ddl_transaction!

  def up
    add_concurrent_index :integrations,
                         [:type_new, :id, :inherit_from_id],
                         name: INDEX_NAME,
                         where: '((active = true) AND (group_id IS NOT NULL))'
  end

  def down
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end
end
