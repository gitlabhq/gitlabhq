# frozen_string_literal: true

class AddAllowedPlanNameUidsToCiRunners < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    add_column :ci_runners, :allowed_plan_name_uids, :smallint,
      array: true, default: [], null: false, if_not_exists: true
  end

  def down
    remove_column :ci_runners, :allowed_plan_name_uids, if_exists: true
  end
end
