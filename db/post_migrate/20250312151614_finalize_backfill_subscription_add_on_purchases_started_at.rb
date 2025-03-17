# frozen_string_literal: true

class FinalizeBackfillSubscriptionAddOnPurchasesStartedAt < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = :subscription_add_on_purchases
  COLUMN_NAME = :id

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSubscriptionAddOnPurchasesStartedAt',
      table_name: TABLE_NAME,
      column_name: COLUMN_NAME,
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
