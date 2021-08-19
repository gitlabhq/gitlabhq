# frozen_string_literal: true

class RemoveIndexContainingFaultyRegex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = "tmp_index_merge_requests_draft_and_status"

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end

  def down
    # noop
    #
  end
end
