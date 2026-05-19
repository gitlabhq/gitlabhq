# frozen_string_literal: true

class SwapColumnsForBulkImportEntitiesSourceXidBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.0'

  TABLE_NAME = :bulk_import_entities
  COLUMN_NAME = :source_xid

  def up
    swap
  end

  def down
    swap
  end

  private

  def swap
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- bigint migration
    with_lock_retries(raise_on_exhaustion: true) do
      swap_columns(TABLE_NAME, COLUMN_NAME, convert_to_bigint_column(COLUMN_NAME))

      reset_all_trigger_functions(TABLE_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end
end
