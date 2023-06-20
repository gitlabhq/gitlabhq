# frozen_string_literal: true

class RemoveMrStateIdTempIndexWithRightColumn < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'merge_requests_state_id_temp_index'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/408766

  def up
    prepare_async_index_removal :merge_requests, :id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_requests, :id, name: INDEX_NAME
  end
end
