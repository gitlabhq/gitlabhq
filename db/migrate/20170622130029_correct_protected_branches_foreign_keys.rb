# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CorrectProtectedBranchesForeignKeys < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_foreign_key_without_error(:protected_branch_push_access_levels,
                                     column: :protected_branch_id)

    execute <<-EOF
    DELETE FROM protected_branch_push_access_levels
    WHERE NOT EXISTS (
      SELECT true
      FROM protected_branches
      WHERE protected_branch_push_access_levels.protected_branch_id = protected_branches.id
    )
    AND protected_branch_id IS NOT NULL
    EOF

    add_concurrent_foreign_key(:protected_branch_push_access_levels,
                               :protected_branches,
                               column: :protected_branch_id)
  end

  def down
    # Previously there was a foreign key without a CASCADING DELETE, so we'll
    # just leave the foreign key in place.
  end

  def remove_foreign_key_without_error(*args)
    remove_foreign_key(*args)
  rescue ArgumentError
  end
end
