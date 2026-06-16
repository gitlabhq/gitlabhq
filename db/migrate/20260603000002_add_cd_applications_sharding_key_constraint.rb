# frozen_string_literal: true

class AddCdApplicationsShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    change_column_null :cd_applications, :group_id, true
    add_multi_column_not_null_constraint(:cd_applications, :group_id, :organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:cd_applications, :group_id, :organization_id)
    change_column_null :cd_applications, :group_id, false
  end
end
