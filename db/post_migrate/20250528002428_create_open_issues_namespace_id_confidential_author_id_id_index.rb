# frozen_string_literal: true

class CreateOpenIssuesNamespaceIdConfidentialAuthorIdIdIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_open_issues_on_namespace_id_confidential_author_id_id'

  def up
    add_concurrent_index :issues, [:namespace_id, :confidential, :author_id, :id], where: 'state_id = 1', name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/510
  end

  def down
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end
end
