module Gitlab
  module Geo
    class OauthApplicationUndefinedError < StandardError; end

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

    def self.license_allows?
      ::License.current && ::License.current.add_on?('GitLab_Geo')
    end

    def self.primary?
      RequestStore.store[:geo_node_primary?] ||= self.enabled? && self.current_node && self.current_node.primary?
    end

    def self.secondary?
      RequestStore.store[:geo_node_secondary] ||= self.enabled? && self.current_node && !self.current_node.primary?
    end

    def self.geo_node?(host:, port:)
      GeoNode.where(host: host, port: port).exists?
    end

    def self.notify_wiki_update(project)
      ::Geo::EnqueueWikiUpdateService.new(project).execute
    end

    def self.bulk_notify_job
      Sidekiq::Cron::Job.find('geo_bulk_notify_worker')
    end

    def self.oauth_authentication
      return false unless Gitlab::Geo.secondary?

      RequestStore.store[:geo_oauth_application] ||= Gitlab::Geo.current_node.oauth_application or
                                                     raise OauthApplicationUndefinedError
    end
  end
end
