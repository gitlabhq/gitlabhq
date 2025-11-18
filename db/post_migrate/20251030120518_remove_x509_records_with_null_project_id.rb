# frozen_string_literal: true

class RemoveX509RecordsWithNullProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  BATCH_SIZE = 1000

  def up
    certificates_relation = define_batchable_model('x509_certificates').where(project_id: nil)
    issuers_relation = define_batchable_model('x509_issuers').where(project_id: nil)

    # Remove certificates without project_id
    loop do
      batch = certificates_relation.limit(BATCH_SIZE)
      delete_count = certificates_relation.where(id: batch.select(:id)).delete_all

      break if delete_count == 0
    end

    # Remove issuers without project_id
    loop do
      batch = issuers_relation.limit(BATCH_SIZE)
      delete_count = issuers_relation.where(id: batch.select(:id)).delete_all

      break if delete_count == 0
    end
  end

  def down
    # Cannot restore deleted records
    # This is intentionally irreversible
  end
end
