# frozen_string_literal: true

class AddPreparedAtCreatedAtIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_requests_id_created_at_prepared_at'

  # TODO: Issue for sync deletion: https://gitlab.com/gitlab-org/gitlab/-/issues/419918

  def up
    prepare_async_index(:merge_requests,
      [:created_at, :id],
      name: INDEX_NAME,
      where: "prepared_at IS NULL")
  end

  def down
    unprepare_async_index(:merge_requests, [:created_at, :id], name: INDEX_NAME)
  end
end
