# frozen_string_literal: true

class PrepareAssigneeIdIndexesForMergeRequestsBigintConversion < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.4'

  TABLE_NAME = 'merge_requests'
  BIGINT_COLUMNS = [
    :assignee_id_convert_to_bigint,
    :merge_user_id_convert_to_bigint,
    :updated_by_id_convert_to_bigint,
    :milestone_id_convert_to_bigint,
    :source_project_id_convert_to_bigint
  ].freeze

  INDEXES = [
    {
      name: 'index_merge_requests_on_assignee_id',
      columns: [:assignee_id_convert_to_bigint]
    },
    {
      name: 'index_merge_requests_on_merge_user_id',
      columns: [:merge_user_id_convert_to_bigint],
      options: { where: "merge_user_id_convert_to_bigint IS NOT NULL" }
    },
    {
      name: 'index_merge_requests_on_updated_by_id',
      columns: [:updated_by_id_convert_to_bigint],
      options: { where: "updated_by_id_convert_to_bigint IS NOT NULL" }
    },
    {
      name: 'index_merge_requests_on_milestone_id',
      columns: [:milestone_id_convert_to_bigint]
    },
    {
      name: 'idx_merge_requests_on_source_project_and_branch_state_opened',
      columns: [:source_project_id_convert_to_bigint, :source_branch],
      options: { where: "state_id = 1" }
    },
    {
      name: 'index_merge_requests_on_source_project_id_and_source_branch',
      columns: [:source_project_id_convert_to_bigint, :source_branch]
    }
  ].freeze

  def up
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- Bigint migration
    INDEXES.each do |index|
      options = index[:options] || {}
      prepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    return if skip_migration?

    INDEXES.each do |index|
      options = index[:options] || {}
      unprepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end
  end

  private

  def skip_migration?
    unless conversion_columns_exist?
      say "No conversion columns found - migration skipped"
      return true
    end

    false
  end

  def conversion_columns_exist?
    BIGINT_COLUMNS.all? { |column| column_exists?(TABLE_NAME, column) }
  end
end
