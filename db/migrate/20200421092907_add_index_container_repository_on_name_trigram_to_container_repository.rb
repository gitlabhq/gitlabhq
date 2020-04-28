# frozen_string_literal: true

class AddIndexContainerRepositoryOnNameTrigramToContainerRepository < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_container_repository_on_name_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :container_repositories, :name, name: INDEX_NAME, using: :gin, opclass: { name: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name(:container_repositories, INDEX_NAME)
  end
end
