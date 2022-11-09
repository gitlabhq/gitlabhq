# frozen_string_literal: true

class SyncNewAmountUsedForCiNamespaceMonthlyUsages < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    namespace_usages = define_batchable_model('ci_namespace_monthly_usages')

    namespace_usages.each_batch(of: 500) do |batch|
      batch.where('amount_used > 0').update_all('new_amount_used = amount_used')
    end
  end

  def down
    # Non reversible migration.
    # This data migration keeps `new_amount_used` in sync with the old `amount_used`.
    # In case of failure or interruption the migration can be retried.
  end
end
