# frozen_string_literal: true

class DropTableCiPlatformMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :ci_platform_metrics

  def up
    with_lock_retries do
      drop_table(TABLE_NAME)
    end
  end

  def down
    with_lock_retries do
      create_table(TABLE_NAME) do |t|
        t.datetime_with_timezone :recorded_at, null: false
        t.text :platform_target, null: false
        t.integer :count, null: false
      end
    end

    add_text_limit(
      TABLE_NAME, :platform_target, 255,
      constraint_name: :check_f922abc32b
    )

    add_check_constraint(
      TABLE_NAME, 'count > 0', :ci_platform_metrics_check_count_positive
    )
  end
end
