# frozen_string_literal: true

class SyncBigintIndexIssuesOnClosedById < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = 'issues'
  BIGINT_COLUMN = :closed_by_id_convert_to_bigint
  INDEX_NAME = 'index_issues_on_closed_by_id'

  def up
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- Bigint migration
    add_concurrent_index TABLE_NAME, [BIGINT_COLUMN], name: bigint_index_name(INDEX_NAME)
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    return if skip_migration?

    remove_concurrent_index_by_name TABLE_NAME, bigint_index_name(INDEX_NAME)
  end

  private

  def skip_migration?
    unless column_exists?(TABLE_NAME, BIGINT_COLUMN)
      say "No conversion column found - migration skipped"
      return true
    end

    false
  end
end
