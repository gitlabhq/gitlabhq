# frozen_string_literal: true

class CreateClosedIncidentsNamespaceIdClosedAtIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_closed_incidents_on_namespace_id_closed_at'

  def up
    add_concurrent_index :issues, [:namespace_id, :closed_at], where: 'state_id = 2 AND work_item_type_id = 2', name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/510
  end

  def down
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end
end
