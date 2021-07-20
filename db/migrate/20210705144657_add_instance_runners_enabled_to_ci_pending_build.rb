# frozen_string_literal: true

class AddInstanceRunnersEnabledToCiPendingBuild < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :ci_pending_builds, :instance_runners_enabled, :boolean, null: false, default: false
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_pending_builds, :instance_runners_enabled
    end
  end
end
