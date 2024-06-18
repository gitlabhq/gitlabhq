# frozen_string_literal: true

class FinalizeBackfillEpicBasicFieldsToWorkItemRecord < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    return if Gitlab.com_except_jh? || Gitlab.dev_or_test_env?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillEpicBasicFieldsToWorkItemRecord',
      table_name: 'epics',
      column_name: 'id',
      job_arguments: ['group_id'],
      finalize: true
    )
  end

  def down; end
end
