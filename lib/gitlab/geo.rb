module Gitlab
  module Geo
    def self.enabled?
      GeoNode.exists?
    end

    def self.current_node
      GeoNode.find_by(host: Gitlab.config.gitlab.host, relative_url_root: Gitlab.config.gitlab.relative_url_root)
    end
  end
end
