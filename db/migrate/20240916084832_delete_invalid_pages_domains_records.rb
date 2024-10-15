# frozen_string_literal: true

class DeleteInvalidPagesDomainsRecords < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.5'

  BATCH_SIZE = 1000

  def up
    relation = define_batchable_model('pages_domains').where(project_id: nil)

    loop do
      batch = relation.limit(BATCH_SIZE)
      delete_count = relation.where(id: batch.select(:id)).delete_all

      break if delete_count == 0
    end
  end

  def down
    # No-op, since we can't restore deleted records
  end
end
