# frozen_string_literal: true

class DropWebHookCallsHighColumn < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      if column_exists?(:plan_limits, :web_hook_calls_high) # rubocop:disable Style/IfUnlessModifier
        remove_column :plan_limits, :web_hook_calls_high
      end
    end
  end

  def down
    with_lock_retries do
      unless column_exists?(:plan_limits, :web_hook_calls_high)
        # rubocop:disable Migration/SchemaAdditionMethodsNoPost
        add_column :plan_limits, :web_hook_calls_high, :integer, default: 0
        # rubocop:enable Migration/SchemaAdditionMethodsNoPost
      end
    end
  end
end
