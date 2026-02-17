# frozen_string_literal: true

class BackfillBulkImportEntitiesSourceXidForBigintConversion < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.9'

  TABLE = :bulk_import_entities
  COLUMNS = %i[source_xid]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 200)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
