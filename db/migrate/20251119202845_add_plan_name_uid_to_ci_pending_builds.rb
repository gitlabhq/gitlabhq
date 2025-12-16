# frozen_string_literal: true

class AddPlanNameUidToCiPendingBuilds < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    add_column :ci_pending_builds, :plan_name_uid, :smallint, if_not_exists: true
  end

  def down
    remove_column :ci_pending_builds, :plan_name_uid, if_exists: true
  end
end
