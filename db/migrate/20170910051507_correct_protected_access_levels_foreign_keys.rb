class CorrectProtectedAccessLevelsForeignKeys < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  SOURCE_TABLES = %w(protected_branch_merge_access_levels
                     protected_branch_push_access_levels
                     protected_tag_create_access_levels).freeze

  disable_ddl_transaction!

  def up
    SOURCE_TABLES.each { |source_table| correct_foreign_key_for_group_id(source_table) }
  end

  def down
    # Previously there was a foreign key without a CASCADING DELETE, so we'll
    # just leave the foreign key in place.
  end

  private

  def correct_foreign_key_for_group_id(source_table)
    remove_foreign_key_without_error(source_table,
                                     column: :group_id)

    execute <<-EOF
    DELETE FROM #{source_table}
    WHERE NOT EXISTS (
      SELECT true
      FROM namespaces
      WHERE #{source_table}.group_id = namespaces.id
      AND namespaces.type = 'Group'
    )
    AND group_id IS NOT NULL
    EOF

    add_concurrent_foreign_key(source_table,
                               :namespaces,
                               column: :group_id)
  end
end
