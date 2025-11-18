# frozen_string_literal: true

class DeleteCodeRepositoryRecords < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.6'

  BATCH_SIZE = 1000

  def up
    # Delete all Code::Repository records to stop indexing
    # before recreating the collection with updated partitions.
    each_batch(:p_ai_active_context_code_repositories, column: :id, of: BATCH_SIZE) do |batch|
      batch.delete_all
    end
  end

  def down
    # no-op: can't recover deleted records
  end
end
