# frozen_string_literal: true

class AddEventsShardingKeyMultiColumnNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:events, :group_id, :project_id, :personal_namespace_id, validate: false)
  end

  def down
    remove_multi_column_not_null_constraint(:events, :group_id, :project_id, :personal_namespace_id)
  end
end
