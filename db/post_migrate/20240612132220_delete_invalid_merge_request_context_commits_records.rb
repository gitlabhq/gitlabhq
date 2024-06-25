# frozen_string_literal: true

class DeleteInvalidMergeRequestContextCommitsRecords < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.2'

  BATCH_SIZE = 1000

  def up
    return if Gitlab.com?

    relation = define_batchable_model('merge_request_context_commits').where(merge_request_id: nil)

    loop do
      batch = relation.limit(BATCH_SIZE)
      delete_count = relation.where(id: batch.select(:id)).delete_all

      break if delete_count == 0
    end
  end

  def down
    # no-op
  end
end
