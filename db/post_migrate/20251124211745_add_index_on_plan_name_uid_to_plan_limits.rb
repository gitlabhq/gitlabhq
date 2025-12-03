# frozen_string_literal: true

class AddIndexOnPlanNameUidToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_plan_limits_on_plan_name_uid'

  def up
    add_concurrent_index :plan_limits, :plan_name_uid, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :plan_limits, INDEX_NAME
  end
end
