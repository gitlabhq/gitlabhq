# frozen_string_literal: true

class DropIndexMergeRequestsOnDescriptionTrigram < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = :merge_requests
  COLUMN = :description
  INDEX_NAME = :index_merge_requests_on_description_trigram

  def up
    # It may be still useful for self-managed so we're dropping it for .com only for now.
    return unless Gitlab.com_except_jh?

    prepare_async_index_removal TABLE_NAME, COLUMN, name: INDEX_NAME
  end

  def down
    return unless Gitlab.com_except_jh?

    unprepare_async_index TABLE_NAME, COLUMN, name: INDEX_NAME
  end
end
