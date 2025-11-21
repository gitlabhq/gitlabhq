# frozen_string_literal: true

class DropNotesArchived < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    drop_table :notes_archived
  end

  def down
    # Using the original migration at db/migrate/20250916221000_create_temporary_notes_archived_table.rb
    # to recreate the table
    # Create table with column definitions, defaults, and identity
    # INCLUDING CONSTRAINTS includes NOT NULL constraints but not CHECK constraints
    unless table_exists?(:notes_archived)
      transaction do
        execute <<~SQL
          CREATE TABLE IF NOT EXISTS notes_archived (
            LIKE notes INCLUDING DEFAULTS INCLUDING IDENTITY INCLUDING COMMENTS
          );
        SQL

        execute <<~SQL
          ALTER TABLE notes_archived ADD PRIMARY KEY (id);
        SQL

        # Add archived_at column using Rails helper instead of raw SQL
        add_column :notes_archived, :archived_at, :timestamptz, default: -> { 'CURRENT_TIMESTAMP' }, if_not_exists: true

        # Add only essential indexes for the migration work
        # rubocop:disable Migration/AddIndex -- This is fine on the down method
        add_index :notes_archived, :namespace_id  # For the backfill queries
        add_index :notes_archived, :project_id    # Required for FK
        add_index :notes_archived, :review_id     # Required for FK
        # rubocop:enable Migration/AddIndex

        # Foreign keys arerestored in a separate migration

        # Add comment indicating temporary nature
        execute <<~SQL
          COMMENT ON TABLE notes_archived IS
          'Temporary table for storing orphaned notes during namespace_id backfill. To be dropped after migration completion.';
        SQL
      end
    end

    # Add text limits matching the original notes table
    add_text_limit :notes_archived, :note, 1_000_000
    add_text_limit :notes_archived, :st_diff, 1_000_000
    add_text_limit :notes_archived, :position, 50_000
    add_text_limit :notes_archived, :original_position, 50_000
    add_text_limit :notes_archived, :note_html, 1_000_000
    add_text_limit :notes_archived, :change_position, 50_000
  end
end
