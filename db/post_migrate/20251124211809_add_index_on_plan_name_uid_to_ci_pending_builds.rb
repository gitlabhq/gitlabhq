# frozen_string_literal: true

class AddIndexOnPlanNameUidToCiPendingBuilds < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_pending_builds_on_plan_name_uid'

  def up
    add_concurrent_index :ci_pending_builds, :plan_name_uid, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pending_builds, INDEX_NAME
  end
end
