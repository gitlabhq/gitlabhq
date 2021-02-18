# frozen_string_literal: true

class CreateCiProjectMonthlyUsage < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :ci_project_monthly_usages, if_not_exists: true do |t|
        t.references :project, foreign_key: { on_delete: :cascade }, index: false, null: false
        t.date :date, null: false
        t.decimal :amount_used, null: false, default: 0.0, precision: 18, scale: 2

        t.index [:project_id, :date], unique: true
      end
    end

    add_check_constraint :ci_project_monthly_usages, "(date = date_trunc('month', date))", 'ci_project_monthly_usages_year_month_constraint'
  end

  def down
    with_lock_retries do
      drop_table :ci_project_monthly_usages
    end
  end
end
