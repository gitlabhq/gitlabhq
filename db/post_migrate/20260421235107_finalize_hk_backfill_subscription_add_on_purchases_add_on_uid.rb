# frozen_string_literal: true

class FinalizeHkBackfillSubscriptionAddOnPurchasesAddOnUid < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSubscriptionAddOnPurchasesAddOnUid',
      table_name: :subscription_add_on_purchases,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
