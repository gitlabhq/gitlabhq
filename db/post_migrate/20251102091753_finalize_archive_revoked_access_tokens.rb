# frozen_string_literal: true

class FinalizeArchiveRevokedAccessTokens < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    return unless Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'ArchiveRevokedAccessTokens',
      table_name: :oauth_access_tokens,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
