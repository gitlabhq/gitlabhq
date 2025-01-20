# frozen_string_literal: true

class FinalizeRestoreOptInToGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'RestoreOptInToGitlabCom',
      table_name: :user_details,
      column_name: :user_id,
      job_arguments: ['temp_user_details_issue18240'],
      finalize: true
    )
  end

  def down; end
end
