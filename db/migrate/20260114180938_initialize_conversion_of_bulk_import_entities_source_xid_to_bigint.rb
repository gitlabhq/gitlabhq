# frozen_string_literal: true

class InitializeConversionOfBulkImportEntitiesSourceXidToBigint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE = :bulk_import_entities
  COLUMNS = %i[source_xid]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
