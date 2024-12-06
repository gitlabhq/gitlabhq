# frozen_string_literal: true

class FinalizeBackfillResourceLinkEvents < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillResourceLinkEvents',
      table_name: :resource_link_events,
      column_name: :id,
      job_arguments: [:namespace_id, :issues, :namespace_id, :issue_id],
      finalize: true
    )
  end

  def down; end
end
