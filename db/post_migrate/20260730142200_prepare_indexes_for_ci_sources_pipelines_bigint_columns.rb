# frozen_string_literal: true

class PrepareIndexesForCiSourcesPipelinesBigintColumns < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '19.3'
  disable_ddl_transaction!

  TABLE_NAME = 'ci_sources_pipelines'
  BIGINT_COLUMNS = [
    :id_convert_to_bigint,
    :project_id_convert_to_bigint,
    :source_project_id_convert_to_bigint
  ].freeze

  INDEXES = [
    {
      name: 'ci_sources_pipelines_pkey',
      columns: [:id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'index_ci_sources_pipelines_on_project_id',
      columns: [:project_id_convert_to_bigint]
    },
    {
      name: 'index_ci_sources_pipelines_on_source_project_id',
      columns: [:source_project_id_convert_to_bigint]
    }
  ].freeze

  # TODO: Indexes to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242049
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
