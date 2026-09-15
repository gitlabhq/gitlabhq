# frozen_string_literal: true

class PrepareIndexesForIssuesBigintConversionBatchOne < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '19.4'
  disable_ddl_transaction!

  # TODO: Indexes to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/611716
  TABLE_NAME = 'issues'
  BIGINT_COLUMNS = [
    :closed_by_id_convert_to_bigint,
    :duplicated_to_id_convert_to_bigint,
    :last_edited_by_id_convert_to_bigint,
    :moved_to_id_convert_to_bigint,
    :promoted_to_epic_id_convert_to_bigint,
    :updated_by_id_convert_to_bigint
  ].freeze

  INDEXES = [
    {
      name: 'index_issues_on_closed_by_id',
      columns: [:closed_by_id_convert_to_bigint]
    },
    {
      name: 'index_issues_on_duplicated_to_id',
      columns: [:duplicated_to_id_convert_to_bigint],
      options: { where: 'duplicated_to_id_convert_to_bigint IS NOT NULL' }
    },
    {
      name: 'index_issues_on_last_edited_by_id',
      columns: [:last_edited_by_id_convert_to_bigint]
    },
    {
      name: 'index_issues_on_moved_to_id',
      columns: [:moved_to_id_convert_to_bigint],
      options: { where: 'moved_to_id_convert_to_bigint IS NOT NULL' }
    },
    {
      name: 'index_issues_on_promoted_to_epic_id',
      columns: [:promoted_to_epic_id_convert_to_bigint],
      options: { where: 'promoted_to_epic_id_convert_to_bigint IS NOT NULL' }
    },
    {
      name: 'index_issues_on_updated_by_id',
      columns: [:updated_by_id_convert_to_bigint],
      options: { where: 'updated_by_id_convert_to_bigint IS NOT NULL' }
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
