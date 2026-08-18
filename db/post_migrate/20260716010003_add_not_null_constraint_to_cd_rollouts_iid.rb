# frozen_string_literal: true

class AddNotNullConstraintToCdRolloutsIid < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  def up
    add_not_null_constraint :cd_rollouts, :iid
  end

  def down
    remove_not_null_constraint :cd_rollouts, :iid
  end
end
