# frozen_string_literal: true

class FinalizeRecoverDeletedMlModelVersionPackages < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'RecoverDeletedMlModelVersionPackages',
      table_name: :ml_model_versions,
      column_name: :id,
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
