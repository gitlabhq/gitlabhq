# frozen_string_literal: true

class FinalizeDisableAllowRunnerRegistrationOnNamespaceSettingsForGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'DisableAllowRunnerRegistrationOnNamespaceSettingsForGitlabCom',
      table_name: :namespaces,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
