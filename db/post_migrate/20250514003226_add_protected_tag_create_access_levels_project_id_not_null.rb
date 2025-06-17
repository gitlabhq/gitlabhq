# frozen_string_literal: true

class AddProtectedTagCreateAccessLevelsProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :protected_tag_create_access_levels, :project_id
  end

  def down
    remove_not_null_constraint :protected_tag_create_access_levels, :project_id
  end
end
