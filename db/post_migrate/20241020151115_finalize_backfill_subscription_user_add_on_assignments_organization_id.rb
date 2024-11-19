# frozen_string_literal: true

class FinalizeBackfillSubscriptionUserAddOnAssignmentsOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSubscriptionUserAddOnAssignmentsOrganizationId',
      table_name: :subscription_user_add_on_assignments,
      column_name: :id,
      job_arguments: [:organization_id, :subscription_add_on_purchases, :organization_id, :add_on_purchase_id],
      finalize: true
    )
  end

  def down; end
end
