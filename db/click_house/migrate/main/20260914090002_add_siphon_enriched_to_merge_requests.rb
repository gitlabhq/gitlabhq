# frozen_string_literal: true

class AddSiphonEnrichedToMergeRequests < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE merge_requests
        ADD COLUMN IF NOT EXISTS _siphon_enriched Bool DEFAULT false CODEC(ZSTD(1))
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE merge_requests
        DROP COLUMN IF EXISTS _siphon_enriched
    SQL
  end
end
