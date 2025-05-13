# frozen_string_literal: true

class CreateAsyncIssuesWorkItemTypeIdNamespaceIdCreatedAtStateIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  INDEX_NAME = 'index_issues_on_work_item_type_id_namespace_id_created_at_state'

  def up
    # To be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/541363
    prepare_async_index :issues, [:work_item_type_id, :namespace_id, :created_at, :state_id], name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/510
  end

  def down
    unprepare_async_index :issues, INDEX_NAME
  end
end
