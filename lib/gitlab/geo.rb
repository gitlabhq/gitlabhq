module Gitlab
  module Geo
    def self.current_node
      RequestStore.store[:geo_node_current] ||= begin
        GeoNode.find_by(host: Gitlab.config.gitlab.host,
                        port: Gitlab.config.gitlab.port,
                        relative_url_root: Gitlab.config.gitlab.relative_url_root)
      end
    end

    def self.primary_node
      RequestStore.store[:geo_primary_node] ||= GeoNode.find_by(primary: true)
    end

    def self.secondary_nodes
      RequestStore.store[:geo_secondary_nodes] ||= GeoNode.where(primary: false)
    end

    def self.enabled?
      RequestStore.store[:geo_node_enabled] ||= GeoNode.exists?
    end

    def self.readonly?
      RequestStore.store[:geo_node_readonly] ||= self.enabled? && self.current_node && !self.current_node.primary?
    end

    def self.geo_node?(host:, port:)
      GeoNode.where(host: host, port: port).exists?
    end

    def self.notify_update(project)
      ::Geo::EnqueueUpdateService.new(project).execute
    end
  end
end
