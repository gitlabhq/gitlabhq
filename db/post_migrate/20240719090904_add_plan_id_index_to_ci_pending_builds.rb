# frozen_string_literal: true

class AddPlanIdIndexToCiPendingBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  PLAN_ID_INDEX = 'index_ci_pending_builds_on_plan_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pending_builds, :plan_id, name: PLAN_ID_INDEX
  end

  def down
    remove_concurrent_index :ci_pending_builds, :plan_id, name: PLAN_ID_INDEX
  end
end
