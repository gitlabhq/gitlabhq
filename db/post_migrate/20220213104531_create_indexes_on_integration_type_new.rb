# frozen_string_literal: true

# Reproduce the indices on integrations.type on integrations.type_new
class CreateIndexesOnIntegrationTypeNew < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE_NAME = :integrations
  COLUMN = :type_new

  def indices
    [
      {
        name: "index_integrations_on_project_and_#{COLUMN}_where_inherit_null",
        columns: [:project_id, COLUMN],
        where: 'inherit_from_id IS NULL'
      },
      {
        name: "index_integrations_on_project_id_and_#{COLUMN}_unique",
        columns: [:project_id, COLUMN],
        unique: true
      },
      {
        name: "index_integrations_on_#{COLUMN}",
        columns: [COLUMN]
      },
      {
        name: "index_integrations_on_#{COLUMN}_and_instance_partial",
        columns: [COLUMN, :instance],
        where: 'instance = true'
      },
      {
        name: "index_integrations_on_#{COLUMN}_and_template_partial",
        columns: [COLUMN, :template],
        where: 'template = true'
      },
      {
        # column names are limited to 63 characters, so this one is re-worded for clarity
        name: "index_integrations_on_#{COLUMN}_id_when_active_and_has_project",
        columns: [COLUMN, :id],
        where: '((active = true) AND (project_id IS NOT NULL))'
      },
      {
        name: "index_integrations_on_unique_group_id_and_#{COLUMN}",
        columns: [:group_id, COLUMN]
      }
    ]
  end

  def up
    indices.each do |index|
      add_concurrent_index TABLE_NAME, index[:columns], index.except(:columns)
    end
  end

  def down
    indices.each do |index|
      remove_concurrent_index_by_name TABLE_NAME, index[:name]
    end
  end
end
