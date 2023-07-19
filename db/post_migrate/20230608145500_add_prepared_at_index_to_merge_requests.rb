# frozen_string_literal: true

class AddPreparedAtIndexToMergeRequests < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_requests_on_id_and_prepared_at'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/415721

  def up
    prepare_async_index(:merge_requests,
      :id,
      name: INDEX_NAME,
      where: "prepared_at IS NULL")
  end

  def down
    unprepare_async_index(:merge_requests, :id, name: INDEX_NAME)
  end
end
