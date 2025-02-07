# frozen_string_literal: true

class AddMilestonesUniqueParentConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_multi_column_not_null_constraint(:milestones, :group_id, :project_id)
  end

  def down
    remove_multi_column_not_null_constraint(:milestones, :group_id, :project_id)
  end
end
