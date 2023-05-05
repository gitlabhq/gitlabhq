# frozen_string_literal: true

class CreateNotNullConstraintReleasesTag < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :releases, :tag, constraint_name: 'releases_not_null_tag', validate: false
  end

  def down
    remove_not_null_constraint :releases, :tag, constraint_name: 'releases_not_null_tag'
  end
end
