# frozen_string_literal: true

class FinalizeBulkImportEntitiesSourceXidBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.0'

  TABLE_NAME = :bulk_import_entities
  COLUMN_NAME = :source_xid

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(
      TABLE_NAME,
      [COLUMN_NAME],
      primary_key: :id
    )
  end

  def down
    # no-op
  end
end
