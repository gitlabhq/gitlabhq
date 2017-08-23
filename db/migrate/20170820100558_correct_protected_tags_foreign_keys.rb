# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CorrectProtectedTagsForeignKeys < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_foreign_key_without_error(:protected_tag_create_access_levels,
                                     column: :protected_tag_id)

    execute <<-EOF
    DELETE FROM protected_tag_create_access_levels
    WHERE NOT EXISTS (
      SELECT true
      FROM protected_tags
      WHERE protected_tag_create_access_levels.protected_tag_id = protected_tags.id
    )
    AND protected_tag_id IS NOT NULL
    EOF

    add_concurrent_foreign_key(:protected_tag_create_access_levels,
                               :protected_tags,
                               column: :protected_tag_id)
  end

  def down
    # Previously there was a foreign key without a CASCADING DELETE, so we'll
    # just leave the foreign key in place.
  end
end
