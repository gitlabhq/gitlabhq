# frozen_string_literal: true

class CreateCiNamespaceMonthlyUsage < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :ci_namespace_monthly_usages, if_not_exists: true do |t|
        t.references :namespace, index: false, null: false
        t.date :date, null: false
        t.integer :additional_amount_available, null: false, default: 0
        t.decimal :amount_used, null: false, default: 0.0, precision: 18, scale: 2

        t.index [:namespace_id, :date], unique: true
      end
    end

    add_check_constraint :ci_namespace_monthly_usages, "(date = date_trunc('month', date))", 'ci_namespace_monthly_usages_year_month_constraint'
  end

  def down
    with_lock_retries do
      drop_table :ci_namespace_monthly_usages
    end
  end
end
