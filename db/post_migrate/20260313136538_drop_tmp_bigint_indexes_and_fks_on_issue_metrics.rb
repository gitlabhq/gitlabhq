# frozen_string_literal: true

class DropTmpBigintIndexesAndFksOnIssueMetrics < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.10'

  TABLE_NAME = 'issue_metrics'
  COLUMNS = %w[id issue_id].freeze

  INDEXES = [
    {
      name: 'index_issue_metrics_on_issue_id_and_timestamps',
      columns: [:issue_id_convert_to_bigint, :first_mentioned_in_commit_at, :first_associated_with_milestone_at,
        :first_added_to_board_at]
    },
    {
      name: 'index_unique_issue_metrics_issue_id',
      columns: [:issue_id_convert_to_bigint],
      options: { unique: true }
    }
  ].freeze

  FOREIGN_KEY = {
    source_table: :issue_metrics,
    column: :issue_id_convert_to_bigint,
    target_table: :issues,
    target_column: :id,
    on_delete: :cascade,
    name: :fk_rails_4bb543d85d
  }.freeze

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index[:name]))
    end

    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(
        FOREIGN_KEY[:source_table],
        FOREIGN_KEY[:target_table],
        name: tmp_foreign_key_name(FOREIGN_KEY[:name]),
        reverse_lock_order: true
      )
    end
  end

  def down
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)

    INDEXES.each do |index|
      options = index[:options] || {}
      add_concurrent_index TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options
    end

    add_concurrent_foreign_key(
      FOREIGN_KEY[:source_table],
      FOREIGN_KEY[:target_table],
      column: FOREIGN_KEY[:column],
      target_column: FOREIGN_KEY[:target_column],
      name: tmp_foreign_key_name(FOREIGN_KEY[:name]),
      on_delete: FOREIGN_KEY[:on_delete],
      validate: true,
      reverse_lock_order: true
    )
  end
end
