# frozen_string_literal: true

class FinalizeHkBackfillOnboardingStatusSetupForCompany < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillOnboardingStatusSetupForCompany',
      table_name: :user_details,
      column_name: :user_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
