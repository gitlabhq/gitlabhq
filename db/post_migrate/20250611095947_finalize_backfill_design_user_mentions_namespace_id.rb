# frozen_string_literal: true

class FinalizeBackfillDesignUserMentionsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDesignUserMentionsNamespaceId',
      table_name: :design_user_mentions,
      column_name: :id,
      job_arguments: [:namespace_id, :design_management_designs, :namespace_id, :design_id],
      finalize: true
    )
  end

  def down; end
end
