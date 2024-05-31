# frozen_string_literal: true

class AddReleasesProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :releases, :project_id
  end

  def down
    remove_not_null_constraint :releases, :project_id
  end
end
