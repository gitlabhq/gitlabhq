# frozen_string_literal: true

class PrepareIndexesForDeploymentsBigintColumnsPhaseTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '18.11'
  disable_ddl_transaction!

  TABLE_NAME = 'deployments'
  BIGINT_COLUMNS = [
    :project_id_convert_to_bigint,
    :user_id_convert_to_bigint
  ].freeze

  INDEXES = [
    {
      name: 'index_deployments_on_archived_project_id_iid',
      columns: [:archived, :project_id_convert_to_bigint, :iid]
    },
    {
      name: 'index_deployments_on_project_and_environment_and_updated_at_id',
      columns: [:project_id_convert_to_bigint, :environment_id, :updated_at, :id]
    },
    {
      name: 'index_deployments_on_project_and_finished',
      columns: [:project_id_convert_to_bigint, :finished_at],
      options: { where: "status = 2" }
    },
    {
      name: 'index_deployments_on_project_id_and_id',
      columns: [:project_id_convert_to_bigint, :id],
      options: { order: { id: :desc } }
    },
    {
      name: 'index_deployments_on_project_id_and_iid',
      columns: [:project_id_convert_to_bigint, :iid],
      options: { unique: true }
    },
    {
      name: 'index_deployments_on_project_id_and_status_and_created_at',
      columns: [:project_id_convert_to_bigint, :status, :created_at]
    },
    {
      name: 'index_deployments_on_project_id_and_updated_at_and_id',
      columns: [:project_id_convert_to_bigint, :updated_at, :id],
      options: { order: { updated_at: :desc, id: :desc } }
    },
    {
      name: 'index_deployments_on_user_id_and_status_and_created_at',
      columns: [:user_id_convert_to_bigint, :status, :created_at],
      exclude_com: true
    }
  ].freeze

  def up
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- Bigint migration
    INDEXES.each do |index|
      next if Gitlab.com_except_jh? && index[:exclude_com]

      options = index[:options] || {}
      prepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    return if skip_migration?

    INDEXES.each do |index|
      next if Gitlab.com_except_jh? && index[:exclude_com]

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
