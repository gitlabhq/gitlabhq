# frozen_string_literal: true

class SyncNewAmountUsedWithAmountUsed < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    # This migration will only run on rollback, there is no need for the positive case
  end

  def down
    project_usages = define_batchable_model('ci_project_monthly_usages')

    project_usages.each_batch(of: 500) do |batch|
      batch.where('amount_used > 0').update_all('new_amount_used = amount_used')
    end
  end
end
