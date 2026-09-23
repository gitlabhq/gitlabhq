# frozen_string_literal: true

class PrepareIndexesForIssuesBigintConversionBatchTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '19.5'
  disable_ddl_transaction!

  # TODO: Indexes to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/611716
  TABLE_NAME = 'issues'
  BIGINT_COLUMNS = [:id_convert_to_bigint].freeze

  INDEXES = [
    {
      name: 'issues_pkey',
      columns: [:id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'index_issues_on_id_and_weight',
      columns: [:id_convert_to_bigint, :weight]
    },
    {
      name: 'index_issues_on_namespace_id_created_at_id_state_id',
      columns: [:namespace_id, :created_at, :id_convert_to_bigint, :state_id]
    },
    {
      name: 'index_issues_on_namespace_id_relative_position_id_state_id',
      columns: [:namespace_id, :relative_position, :id_convert_to_bigint, :state_id]
    },
    {
      name: 'index_issues_on_namespace_id_updated_at_id_state_id',
      columns: [:namespace_id, :updated_at, :id_convert_to_bigint, :state_id]
    },
    {
      name: 'index_issues_on_milestone_id_and_id',
      columns: [:milestone_id, :id_convert_to_bigint]
    },
    {
      name: 'idx_issues_on_project_id_and_created_at_and_id_and_state_id',
      columns: [:project_id, :created_at, :id_convert_to_bigint, :state_id]
    },
    {
      name: 'idx_issues_on_project_id_and_due_date_and_id_and_state_id',
      columns: [:project_id, :due_date, :id_convert_to_bigint, :state_id],
      options: { where: 'due_date IS NOT NULL' }
    },
    {
      name: 'idx_issues_on_project_id_and_rel_position_and_id_and_state_id',
      columns: [:project_id, :relative_position, :id_convert_to_bigint, :state_id]
    },
    {
      name: 'idx_issues_on_project_id_and_updated_at_and_id_and_state_id',
      columns: [:project_id, :updated_at, :id_convert_to_bigint, :state_id]
    },
    {
      name: 'index_issues_on_project_id_closed_at_desc_state_id_and_id',
      columns: 'project_id, closed_at DESC NULLS LAST, state_id, id_convert_to_bigint'
    },
    {
      name: 'idx_open_issues_on_project_and_confidential_and_author_and_id',
      columns: [:project_id, :confidential, :author_id, :id_convert_to_bigint],
      options: { where: 'state_id = 1' }
    },
    {
      name: 'index_open_issues_on_namespace_id_confidential_author_id_id',
      columns: [:namespace_id, :confidential, :author_id, :id_convert_to_bigint],
      options: { where: 'state_id = 1' }
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
