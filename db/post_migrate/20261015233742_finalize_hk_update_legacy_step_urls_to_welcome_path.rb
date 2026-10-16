# frozen_string_literal: true

class FinalizeHkUpdateLegacyStepUrlsToWelcomePath < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'UpdateLegacyStepUrlsToWelcomePath',
      table_name: :user_details,
      column_name: :user_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
