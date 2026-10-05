# frozen_string_literal: true

class SyncBigintIndexIssuesOnProjectIdClosedAtStateIdAndId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = 'issues'
  BIGINT_COLUMN = :id_convert_to_bigint
  INDEX_NAME = 'index_issues_on_project_id_closed_at_desc_state_id_and_id'
  # Passed as separate columns rather than one SQL string so that `index_exists?`
  # can match the already-created index: it compares the column list as an array.
  COLUMNS = [:project_id, :closed_at, :state_id, :id_convert_to_bigint].freeze
  OPTIONS = { order: { closed_at: 'DESC NULLS LAST' } }.freeze

  def up
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- Bigint migration
    add_concurrent_index TABLE_NAME, COLUMNS, name: bigint_index_name(INDEX_NAME), **OPTIONS
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
