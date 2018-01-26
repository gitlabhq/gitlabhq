class StoreGeoNodesUrlDirectly < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class GeoNode < ActiveRecord::Base
    def compute_unified_url!
      uri = URI.parse("#{schema}://#{host}#{relative_url_root}")
      uri.port = port if port.present?
      uri.path += '/' unless uri.path.end_with?('/')

      update!(url: uri.to_s)
    end

    def compute_split_url!
      uri = URI.parse(url)

      update!(
        schema: uri.scheme,
        host: uri.host,
        port: uri.port,
        relative_url_root: uri.path
      )
    end
  end

  def up
    add_column :geo_nodes, :url, :string

    GeoNode.find_each { |node| node.compute_unified_url! }

    change_column_null(:geo_nodes, :url, false)
  end

  def down
    GeoNode.find_each { |node| node.compute_split_url! }

    remove_column :geo_nodes, :url, :string
  end
end
