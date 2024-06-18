# frozen_string_literal: true

class AddCodeSuggestionContextDataFields < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE code_suggestion_usages
        ADD COLUMN IF NOT EXISTS unique_tracking_id String DEFAULT '',
        ADD COLUMN IF NOT EXISTS language LowCardinality(String) DEFAULT '',
        ADD COLUMN IF NOT EXISTS suggestion_size UInt64 DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE code_suggestion_usages
        DROP COLUMN IF EXISTS unique_tracking_id,
        DROP COLUMN IF EXISTS language,
        DROP COLUMN IF EXISTS suggestion_size
    SQL
  end
end
