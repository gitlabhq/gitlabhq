# frozen_string_literal: true

class CreateIssuesNamespaceIdCreatedAtIdStateIdIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_namespace_id_created_at_id_state_id'

  def up
    add_concurrent_index :issues, [:namespace_id, :created_at, :id, :state_id], name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/510
  end

  def down
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end
end
