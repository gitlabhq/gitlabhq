# frozen_string_literal: true

class InitConversionForMergeRequestDiffsIdColumnsBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  TABLE = :merge_request_diffs
  COLUMNS = %i[id merge_request_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
