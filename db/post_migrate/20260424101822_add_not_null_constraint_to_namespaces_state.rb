# frozen_string_literal: true

class AddNotNullConstraintToNamespacesState < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  # Disabled as part of the revert of !233206.
  # The NOT NULL constraint on namespaces.state is being reverted.

  # no-op
  def up; end

  def down
    remove_not_null_constraint :namespaces, :state
  end
end
