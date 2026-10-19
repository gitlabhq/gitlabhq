# frozen_string_literal: true

class FinalizeHkNullifyPersonalNamespaceIdOnGroupWikiEvents < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'NullifyPersonalNamespaceIdOnGroupWikiEvents',
      table_name: :events,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
