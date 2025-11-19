# frozen_string_literal: true

class CreateAwardEmojiArchived < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    execute <<~SQL
      CREATE TABLE award_emoji_archived (
        LIKE award_emoji
      );
    SQL

    execute <<~SQL
      ALTER TABLE award_emoji_archived ADD PRIMARY KEY (id);
    SQL

    add_column :award_emoji_archived,
      :archived_at, :timestamptz, default: -> { 'CURRENT_TIMESTAMP' }

    execute <<~SQL
      COMMENT ON TABLE award_emoji_archived IS
      'Temporary table for storing orphaned award_emoji during sharding key backfill. To be dropped after migration completion.';
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS award_emoji_archived;
    SQL
  end
end
