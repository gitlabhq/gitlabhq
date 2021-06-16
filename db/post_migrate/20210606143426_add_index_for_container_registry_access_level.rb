# frozen_string_literal: true

class AddIndexForContainerRegistryAccessLevel < ActiveRecord::Migration[6.1]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX = 'index_project_features_on_project_id_include_container_registry'

  def up
    if index_exists_by_name?('project_features', INDEX)
      Gitlab::AppLogger.warn "Index not created because it already exists (this may be due to an aborted migration or similar): table_name: project_features, index_name: #{INDEX}"
      return
    end

    begin
      disable_statement_timeout do
        execute "CREATE UNIQUE INDEX CONCURRENTLY #{INDEX} ON project_features " \
          'USING btree (project_id) INCLUDE (container_registry_access_level)'
      end
    rescue ActiveRecord::StatementInvalid => ex
      raise "The index #{INDEX} couldn't be added: #{ex.message}"
    end

    create_comment(
      'INDEX',
      INDEX,
      'Included column (container_registry_access_level) improves performance of the ContainerRepository.for_group_and_its_subgroups scope query'
    )
  end

  def down
    remove_concurrent_index_by_name('project_features', INDEX)
  end
end
