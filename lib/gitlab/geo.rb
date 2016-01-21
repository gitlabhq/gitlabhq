module Gitlab
  module Geo
    def self.current_node
      GeoNode.find_by(host: Gitlab.config.gitlab.host,
                      port: Gitlab.config.gitlab.port,
                      relative_url_root: Gitlab.config.gitlab.relative_url_root)
    end

    def self.primary_node
      GeoNode.find_by(primary: true)
    end

    def self.enabled?
      GeoNode.exists?
    end

    def self.readonly?
      self.enabled? && !self.current_node.primary?
    end

    def self.geo_node?(host:, port:)
      GeoNode.where(host: host, port: port).exists?
    end
  end
end
