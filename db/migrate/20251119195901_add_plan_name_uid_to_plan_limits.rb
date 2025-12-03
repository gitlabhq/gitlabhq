# frozen_string_literal: true

class AddPlanNameUidToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    add_column :plan_limits, :plan_name_uid, :smallint, if_not_exists: true
  end

  def down
    remove_column :plan_limits, :plan_name_uid, if_exists: true
  end
end
