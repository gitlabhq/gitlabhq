# frozen_string_literal: true

class AddIndexToAmrruOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'index_approval_merge_request_rules_users_on_project_id'

  def up
    # NOTE: the index was created in https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/post_migrate/20250304132249_prepare_index_approval_merge_request_rules_users_on_project_id.rb
    # rubocop:disable Migration/PreventIndexCreation -- Needed index for sharding key
    add_concurrent_index :approval_merge_request_rules_users, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules_users, name: INDEX_NAME
  end
end
