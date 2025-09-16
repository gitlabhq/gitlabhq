# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToZentaoTrackerData < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(
      :zentao_tracker_data,
      :group_id,
      :project_id,
      :organization_id
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      :zentao_tracker_data,
      :group_id,
      :project_id,
      :organization_id
    )
  end
end
