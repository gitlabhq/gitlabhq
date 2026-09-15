# frozen_string_literal: true

class AddCreatedByDuoToMergeRequests < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE merge_requests ADD COLUMN IF NOT EXISTS created_by_duo Bool DEFAULT false CODEC(ZSTD(1))
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE merge_requests DROP COLUMN IF EXISTS created_by_duo
    SQL
  end
end
