# frozen_string_literal: true

class AddNamespacesStateNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    add_not_null_constraint :namespaces, :state, validate: false
  end

  def down
    remove_not_null_constraint :namespaces, :state
  end
end
