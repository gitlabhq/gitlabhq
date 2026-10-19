# frozen_string_literal: true

class FinalizeRecalculateMinAccessTwoFactorEnforcementOnMembers < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'RecalculateMinAccessTwoFactorEnforcementOnMembers',
      table_name: :members,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
