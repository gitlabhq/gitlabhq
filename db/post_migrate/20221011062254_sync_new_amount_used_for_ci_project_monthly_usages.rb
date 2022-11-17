# frozen_string_literal: true

class SyncNewAmountUsedForCiProjectMonthlyUsages < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    project_usages = define_batchable_model('ci_project_monthly_usages')

    project_usages.each_batch(of: 500) do |batch|
      batch.where('amount_used > 0').update_all('new_amount_used = amount_used')
    end
  end

  def down
    # Non reversible migration.
    # This data migration keeps `new_amount_used` in sync with the old `amount_used`.
    # In case of failure or interruption the migration can be retried.
  end
end
