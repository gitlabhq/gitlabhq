# frozen_string_literal: true

class FinalizeUuidBackfilling < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # This is copied from FinalizeBackfillUuidConversionColumnInVulnerabilityOccurrences
    # to fix https://gitlab.com/gitlab-org/gitlab/-/issues/438311
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillUuidConversionColumnInVulnerabilityOccurrences',
      table_name: :vulnerability_occurrences,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
