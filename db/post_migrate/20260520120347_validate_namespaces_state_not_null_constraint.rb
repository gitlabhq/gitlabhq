# frozen_string_literal: true

class ValidateNamespacesStateNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  def up
    validate_not_null_constraint :namespaces, :state
  end

  def down
    # no-op
  end
end
