# frozen_string_literal: true

class FinalizeBackfillRootStorageStatisticsForkStorageSizes < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillRootStorageStatisticsForkStorageSizes',
      table_name: :namespace_root_storage_statistics,
      column_name: :namespace_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
