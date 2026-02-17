# frozen_string_literal: true

class AddSourceXidConvertToBigintToSiphonBulkImportEntities < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_bulk_import_entities
        ADD COLUMN IF NOT EXISTS source_xid_convert_to_bigint Nullable(Int64)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_bulk_import_entities
        DROP COLUMN IF EXISTS source_xid_convert_to_bigint
    SQL
  end
end
