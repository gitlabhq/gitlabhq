# frozen_string_literal: true

class AddIndexOnRoutePathTrigram < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_routes_on_path_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :routes, :path, name: INDEX_NAME, using: :gin, opclass: { path: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name(:routes, INDEX_NAME)
  end
end
