# frozen_string_literal: true

class PrepareIndexApprovalMergeRequestRulesUsersOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_merge_request_rules_users_on_project_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Needed index for sharding key
    prepare_async_index :approval_merge_request_rules_users, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :approval_merge_request_rules_users, INDEX_NAME
  end
end
