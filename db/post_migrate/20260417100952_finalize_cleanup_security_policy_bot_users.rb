# frozen_string_literal: true

class FinalizeCleanupSecurityPolicyBotUsers < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # The original BBM was only queued on GitLab.com (see QueueCleanupSecurityPolicyBotUsers).
  # ensure_batched_background_migration_is_finished is a no-op when the migration does not exist,
  # so no guard is needed for self-managed instances.
  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CleanupSecurityPolicyBotUsers',
      table_name: :users,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
