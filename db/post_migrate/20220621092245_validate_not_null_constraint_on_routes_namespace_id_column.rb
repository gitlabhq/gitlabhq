# frozen_string_literal: true

class ValidateNotNullConstraintOnRoutesNamespaceIdColumn < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    validate_not_null_constraint :routes, :namespace_id
  end

  def down
    remove_not_null_constraint :routes, :namespace_id
    add_not_null_constraint :routes, :namespace_id, validate: false
  end
end
