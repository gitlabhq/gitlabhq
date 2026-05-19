# frozen_string_literal: true

class RemoveNotNullConstraintFromNamespacesState < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    remove_not_null_constraint :namespaces, :state
  end

  # no-op
  def down; end
end
