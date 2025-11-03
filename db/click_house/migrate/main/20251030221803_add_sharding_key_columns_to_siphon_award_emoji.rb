# frozen_string_literal: true

class AddShardingKeyColumnsToSiphonAwardEmoji < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_award_emoji ADD COLUMN IF NOT EXISTS namespace_id Nullable(Int64);
    SQL
    execute <<~SQL
      ALTER TABLE siphon_award_emoji ADD COLUMN IF NOT EXISTS organization_id Nullable(Int64);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_award_emoji DROP COLUMN IF EXISTS namespace_id;
    SQL
    execute <<~SQL
      ALTER TABLE siphon_award_emoji DROP COLUMN IF EXISTS organization_id;
    SQL
  end
end
