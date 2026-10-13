# frozen_string_literal: true

class SyncBigintIndexIssuesOnNamespaceIdCreatedAtIdStateId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = 'issues'
  BIGINT_COLUMN = :id_convert_to_bigint
  INDEX_NAME = 'index_issues_on_namespace_id_created_at_id_state_id'
  COLUMNS = [:namespace_id, :created_at, :id_convert_to_bigint, :state_id]

  def up
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- Bigint migration
    add_concurrent_index TABLE_NAME, COLUMNS, name: bigint_index_name(INDEX_NAME)
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
