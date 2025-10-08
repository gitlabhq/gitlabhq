# frozen_string_literal: true

class CreateLabelLinksArchivedTable < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS label_links_archived (
        LIKE label_links
      );
    SQL

    execute <<~SQL
      ALTER TABLE label_links_archived ADD PRIMARY KEY (id);
    SQL

    add_column :label_links_archived,
      :archived_at, :timestamptz, default: -> { 'CURRENT_TIMESTAMP' }, if_not_exists: true

    execute <<~SQL
      COMMENT ON TABLE label_links_archived IS
      'Temporary table for storing orphaned label_links during namespace_id backfill. To be dropped after migration completion.';
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS label_links_archived;
    SQL
  end
end
