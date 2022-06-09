# frozen_string_literal: true

class AddNotNullConstraintOnRoutesNamespaceId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :routes, :namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :routes, :namespace_id
  end
end
