# frozen_string_literal: true

class PrepareIndexesForDeploymentsBigintColumnsPhaseOne < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '18.6'
  disable_ddl_transaction!

  TABLE_NAME = 'deployments'
  BIGINT_COLUMNS = [
    :id_convert_to_bigint,
    :environment_id_convert_to_bigint
  ].freeze

  # To be done in PhaseTwo
  # :project_id_convert_to_bigint,
  # :user_id_convert_to_bigint

  INDEXES = [
    {
      name: 'deployment_id_pkey',
      columns: [:id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'index_deployments_for_visible_scope',
      columns: [:environment_id_convert_to_bigint, :finished_at],
      options: { order: { finished_at: :desc }, where: "status IN (1, 2, 3, 4, 6)" }
    },
    {
      name: 'index_deployments_on_environment_id_and_id',
      columns: [:environment_id_convert_to_bigint, :id_convert_to_bigint]
    },
    {
      name: 'index_deployments_on_environment_id_and_ref',
      columns: [:environment_id_convert_to_bigint, :ref]
    },
    {
      name: 'index_deployments_on_environment_id_status_and_finished_at',
      columns: [:environment_id_convert_to_bigint, :status, :finished_at]
    },
    {
      name: 'index_deployments_on_environment_id_status_and_id',
      columns: [:environment_id_convert_to_bigint, :status, :id_convert_to_bigint]
    },
    {
      name: 'index_deployments_on_environment_status_sha',
      columns: [:environment_id_convert_to_bigint, :status, :sha]
    },
    {
      name: 'index_deployments_on_id_and_status_and_created_at',
      columns: [:id_convert_to_bigint, :status, :created_at],
      exclude_com: true
    },
    {
      name: 'index_deployments_on_project_and_environment_and_updated_at_id',
      columns: [:project_id, :environment_id_convert_to_bigint, :updated_at, :id_convert_to_bigint]
    },
    {
      name: 'index_deployments_on_project_id_and_id',
      columns: [:project_id, :id_convert_to_bigint],
      options: { order: { id_convert_to_bigint: :desc } }
    },
    {
      name: 'index_deployments_on_project_id_and_updated_at_and_id',
      columns: [:project_id, :updated_at, :id_convert_to_bigint],
      options: { order: { updated_at: :desc, id_convert_to_bigint: :desc } }
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
