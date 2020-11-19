# frozen_string_literal: true

class AddIndexRouteOnNameTrigramToRoute < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_route_on_name_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :routes, :name, name: INDEX_NAME, using: :gin, opclass: { name: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name(:routes, INDEX_NAME)
  end
end
