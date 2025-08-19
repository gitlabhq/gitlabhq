# frozen_string_literal: true

class AddRedirectRoutesNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :redirect_routes, :namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :redirect_routes, :namespace_id
  end
end
