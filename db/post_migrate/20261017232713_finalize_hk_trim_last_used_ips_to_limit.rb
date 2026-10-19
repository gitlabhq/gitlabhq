# frozen_string_literal: true

class FinalizeHkTrimLastUsedIpsToLimit < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'TrimLastUsedIpsToLimit',
      table_name: :personal_access_token_last_used_ips,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
