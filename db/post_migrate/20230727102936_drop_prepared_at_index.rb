# frozen_string_literal: true

class DropPreparedAtIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_requests_on_id_and_prepared_at'

  # TODO: Issue for sync deletion: https://gitlab.com/gitlab-org/gitlab/-/issues/419917

  def up
    prepare_async_index_removal :merge_requests, :id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_requests, :id, name: INDEX_NAME
  end
end
