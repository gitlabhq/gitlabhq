# frozen_string_literal: true

class AddPlanNameUidToPlans < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :plans, :plan_name_uid, :smallint
  end
end
