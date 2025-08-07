# frozen_string_literal: true

class FinalizeMergeRequestDiffsIdBigintConversion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.3'

  TABLE_NAME = 'merge_request_diffs'
  COLUMNS = %i[id merge_request_id].freeze

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(
      TABLE_NAME,
      COLUMNS
    )
  end

  def down; end
end
