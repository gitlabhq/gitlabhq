# frozen_string_literal: true

class AddNotNullConstraintToRemoteMirrors < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :remote_mirrors, :project_id
  end

  def down
    remove_not_null_constraint :remote_mirrors, :project_id
  end
end
