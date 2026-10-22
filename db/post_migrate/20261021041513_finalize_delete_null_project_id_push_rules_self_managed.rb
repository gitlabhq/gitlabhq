# frozen_string_literal: true

class FinalizeDeleteNullProjectIdPushRulesSelfManaged < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return if Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'DeleteNullProjectIdPushRules',
      table_name: :push_rules,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # Finalization cannot be reversed.
  end
end
