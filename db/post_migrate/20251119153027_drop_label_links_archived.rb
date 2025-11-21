# frozen_string_literal: true

class DropLabelLinksArchived < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    drop_table :label_links_archived
  end

  def down
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
end
