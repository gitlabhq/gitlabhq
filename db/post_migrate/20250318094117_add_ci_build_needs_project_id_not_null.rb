# frozen_string_literal: true

class AddCiBuildNeedsProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :ci_build_needs, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :ci_build_needs, :project_id
  end
end
