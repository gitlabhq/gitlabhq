# frozen_string_literal: true

class CreateIssuesWorkItemTypeIdNamespaceIdCreatedAtStateIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_work_item_type_id_namespace_id_created_at_state'

  def up
    add_concurrent_index :issues, [:work_item_type_id, :namespace_id, :created_at, :state_id], name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/510
  end

  def down
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end
end
