# frozen_string_literal: true

class FinalizeHkBackfillDisplayGitlabCreditsUserDataForNamespaceSetting < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDisplayGitlabCreditsUserDataForNamespaceSetting',
      table_name: :namespace_settings,
      column_name: :namespace_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
