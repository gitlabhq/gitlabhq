# frozen_string_literal: true

class DeleteInvalidRemoteMirrorsRecords < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    return if Gitlab.com?

    relation = define_batchable_model('remote_mirrors').where(project_id: nil)

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
