# frozen_string_literal: true

class DropAwardEmojiArchivedTable < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    drop_table :award_emoji_archived
  end

  def down
    execute <<~SQL
      CREATE TABLE award_emoji_archived (
        id bigint NOT NULL,
        name character varying,
        user_id bigint,
        awardable_type character varying,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        awardable_id bigint,
        namespace_id bigint,
        organization_id bigint,
        archived_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
      );

      COMMENT ON TABLE award_emoji_archived IS 'Temporary table for storing orphaned award_emoji during sharding key backfill. To be dropped after migration completion.';

      ALTER TABLE ONLY award_emoji_archived
        ADD CONSTRAINT award_emoji_archived_pkey PRIMARY KEY (id);
    SQL
  end
end
