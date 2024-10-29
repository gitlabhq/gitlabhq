# frozen_string_literal: true

class UpdateInvalidCiDeletedObjectRecords < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  TABLE_NAME = :ci_deleted_objects
  BATCH_SIZE = 1000

  def up
    return if Gitlab.com?

    relation = define_batchable_model(TABLE_NAME).where(project_id: nil)

    loop do
      batch = relation.limit(BATCH_SIZE)
      update_count = relation.where(id: batch.select(:id)).update_all(project_id: -1)

      break if update_count == 0
    end
  end

  def down
    # no-op
  end
end
