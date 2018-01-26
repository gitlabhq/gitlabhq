# rubocop:disable Migration/RemoveColumn
class RemoveOldElasticsearchSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true

  DOWNTIME_REASON = 'Removing two columns from application_settings'

  def change
    remove_column :application_settings, :elasticsearch_host, :string, default: 'localhost'
    remove_column :application_settings, :elasticsearch_port, :string, default: '9200'
  end
end
