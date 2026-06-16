# frozen_string_literal: true

class CleanUpBigintConversionForBulkImportEntities < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  TABLE = :bulk_import_entities
  COLUMNS = %i[source_xid]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
