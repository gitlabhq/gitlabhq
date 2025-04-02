# frozen_string_literal: true

class RemoveDeploymentDataFromPagesMetadatum < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  TABLE_NAME = :project_pages_metadata
  INDEXES = [
    {
      name: :index_project_pages_metadata_on_project_id_and_deployed_is_true,
      columns: [:project_id],
      options: { where: 'deployed = true' }
    },
    {
      name: :index_project_pages_metadata_on_pages_deployment_id,
      columns: [:pages_deployment_id],
      options: {}
    },
    {
      name: :index_on_pages_metadata_not_migrated,
      columns: [:project_id],
      options: { where: '(deployed = true) AND (pages_deployment_id IS NULL)' }
    }
  ]

  def up
    remove_foreign_key_if_exists TABLE_NAME, column: :pages_deployment_id

    INDEXES.each do |index|
      remove_concurrent_index_by_name TABLE_NAME, index[:name]
    end

    remove_columns TABLE_NAME, :deployed, :pages_deployment_id
  end

  def down
    add_column :project_pages_metadata, :deployed, :boolean, default: false, null: false
    add_column :project_pages_metadata, :pages_deployment_id, :bigint, null: true
    add_concurrent_foreign_key TABLE_NAME, :pages_deployments,
      column: :pages_deployment_id,
      on_delete: :nullify

    INDEXES.each do |index|
      add_concurrent_index(
        TABLE_NAME, index[:columns],
        name: index[:name], **index.fetch(:options, {})
      )
    end
  end
end
