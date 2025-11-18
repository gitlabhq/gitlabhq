# frozen_string_literal: true

class AddPlanNameUidConstraints < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!
  INDEX_NAME = 'index_plans_on_plan_name_uid'

  def up
    add_not_null_constraint :plans, :plan_name_uid
    add_concurrent_index :plans, :plan_name_uid, unique: true, name: INDEX_NAME
  end

  def down
    remove_not_null_constraint :plans, :plan_name_uid
    remove_concurrent_index_by_name :plans, INDEX_NAME
  end
end
