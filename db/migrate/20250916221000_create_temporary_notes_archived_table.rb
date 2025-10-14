# frozen_string_literal: true

class CreateTemporaryNotesArchivedTable < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    # Create table with column definitions, defaults, and identity
    # INCLUDING CONSTRAINTS includes NOT NULL constraints but not CHECK constraints
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS notes_archived (
        LIKE notes INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING IDENTITY INCLUDING COMMENTS
      );
    SQL

    # Explicitly add primary key constraint (INCLUDING CONSTRAINTS doesn't copy PKs)
    execute <<~SQL
      ALTER TABLE notes_archived ADD PRIMARY KEY (id);
    SQL

    # Manually add the CHECK constraint that ensures at least one parent reference exists
    # This constraint exists on the notes table and should be maintained for archived notes
    execute <<~SQL
      ALTER TABLE notes_archived
      ADD CONSTRAINT check_notes_archived_has_parent
      CHECK (num_nonnulls(namespace_id, organization_id, project_id) >= 1)
      NOT VALID;
    SQL

    # Add archived_at column using Rails helper instead of raw SQL
    add_column :notes_archived, :archived_at, :timestamptz, default: -> { 'CURRENT_TIMESTAMP' }, if_not_exists: true

    # Add only essential indexes for the migration work
    add_concurrent_index :notes_archived, :namespace_id  # For the backfill queries
    add_concurrent_index :notes_archived, :project_id    # Required for FK
    add_concurrent_index :notes_archived, :review_id     # Required for FK

    # Add text limits matching the original notes table
    add_text_limit :notes_archived, :note, 1_000_000
    add_text_limit :notes_archived, :st_diff, 1_000_000
    add_text_limit :notes_archived, :position, 50_000
    add_text_limit :notes_archived, :original_position, 50_000
    add_text_limit :notes_archived, :note_html, 1_000_000
    add_text_limit :notes_archived, :change_position, 50_000

    # Add only the foreign key constraints that exist on the original notes table
    add_concurrent_foreign_key :notes_archived, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :notes_archived, :reviews, column: :review_id, on_delete: :nullify
    add_concurrent_foreign_key :notes_archived, :namespaces, column: :namespace_id, on_delete: :cascade

    # Add comment indicating temporary nature
    execute <<~SQL
      COMMENT ON TABLE notes_archived IS
      'Temporary table for storing orphaned notes during namespace_id backfill. To be dropped after migration completion.';
    SQL
  end

  def down
    drop_table :notes_archived, if_exists: true
  end
end
