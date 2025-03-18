# frozen_string_literal: true

class AddBillingMonthYearIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  INDEX_NAME = 'idx_gitlab_hosted_runner_monthly_usages_on_billing_month_year'

  def up
    add_concurrent_index :ci_gitlab_hosted_runner_monthly_usages, "EXTRACT(YEAR FROM billing_month)", name: INDEX_NAME,
      using: :btree
  end

  def down
    remove_concurrent_index_by_name :ci_gitlab_hosted_runner_monthly_usages, name: INDEX_NAME
  end
end
