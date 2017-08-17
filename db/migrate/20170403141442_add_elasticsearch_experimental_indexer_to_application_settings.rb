# rubocop:disable Migration/SaferBooleanColumn
class AddElasticsearchExperimentalIndexerToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :application_settings, :elasticsearch_experimental_indexer, :boolean
  end

  def down
    remove_column :application_settings, :elasticsearch_experimental_indexer
  end
end
