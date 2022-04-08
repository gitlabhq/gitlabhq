# frozen_string_literal: true

class AddNotNullContraintToProjectNamespaceId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :projects, :project_namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :projects, :project_namespace_id
  end
end
