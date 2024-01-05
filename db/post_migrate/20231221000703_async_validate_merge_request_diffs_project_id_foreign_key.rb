# frozen_string_literal: true

class AsyncValidateMergeRequestDiffsProjectIdForeignKey < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def up
    prepare_async_foreign_key_validation :merge_request_diffs, :project_id
  end

  def down
    unprepare_async_foreign_key_validation :merge_request_diffs, :project_id
  end
end
