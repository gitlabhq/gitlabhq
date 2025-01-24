# frozen_string_literal: true

# Dedicated only
class CreateCiGitlabHostedRunnerMonthlyUsages < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/EnsureFactoryForTable -- False Positive
    create_table :ci_gitlab_hosted_runner_monthly_usages do |t|
      # 8 bytes
      t.references :runner,
        type: :bigint, index: false, null: false
      t.bigint :runner_duration_seconds, null: false, default: 0
      t.bigint :project_id, null: false
      t.bigint :root_namespace_id, null: false
      t.timestamps_with_timezone null: false
      # 4 bytes
      t.date :billing_month, null: false
      t.integer :notification_level, null: false, default: 100
      # variables bytes
      t.decimal :compute_minutes_used, precision: 18, scale: 4, null: false, default: 0.0
    end

    add_index :ci_gitlab_hosted_runner_monthly_usages, [:root_namespace_id, :billing_month],
      name: 'idx_hosted_runner_usage_on_namespace_billing_month'

    add_index :ci_gitlab_hosted_runner_monthly_usages, [:project_id, :billing_month],
      name: 'idx_hosted_runner_usage_on_project_billing_month'

    add_index :ci_gitlab_hosted_runner_monthly_usages,
      [:runner_id, :billing_month, :root_namespace_id, :project_id],
      name: 'idx_hosted_runner_usage_unique',
      unique: true

    add_check_constraint(
      :ci_gitlab_hosted_runner_monthly_usages,
      "(billing_month = date_trunc('month', billing_month::timestamp with time zone))",
      'ci_hosted_runner_monthly_usages_month_constraint'
    )
    # rubocop:enable Migration/EnsureFactoryForTable -- False Positive
  end

  def down
    drop_table :ci_gitlab_hosted_runner_monthly_usages if table_exists? :ci_gitlab_hosted_runner_monthly_usages
  end
end
