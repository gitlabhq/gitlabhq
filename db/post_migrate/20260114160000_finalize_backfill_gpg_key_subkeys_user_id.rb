# frozen_string_literal: true

class FinalizeBackfillGpgKeySubkeysUserId < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillGpgKeySubkeysUserId',
      table_name: :gpg_key_subkeys,
      column_name: :id,
      job_arguments: [:user_id, :gpg_keys, :user_id, :gpg_key_id],
      finalize: true
    )
  end

  def down; end
end
