# frozen_string_literal: true

class RemoveDeprecatedCiRunnerColumn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :ci_runners, :is_shared
    end
  end

  def down
    add_column :ci_runners, :is_shared, :boolean, default: false unless column_exists?(:ci_runners, :is_shared)

    add_concurrent_index :ci_runners, :is_shared
  end
end
