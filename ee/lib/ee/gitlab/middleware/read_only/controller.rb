module EE
  module Gitlab
    module Middleware
      module ReadOnly
        module Controller
          extend ::Gitlab::Utils::Override

          WHITELISTED_GEO_ROUTES = {
            'admin/geo_nodes' => %w{update}
          }.freeze

          WHITELISTED_GEO_ROUTES_TRACKING_DB = {
            'admin/geo_projects' => %w{resync recheck force_redownload}
          }.freeze

          private

          override :whitelisted_routes
          def whitelisted_routes
            super || geo_node_update_route || geo_proxy_git_push_ssh_route
          end

          def geo_node_update_route
            # Calling route_hash may be expensive. Only do it if we think there's a possible match
            return false unless request.path =~ %r{/admin/geo_}

            controller = route_hash[:controller]
            action = route_hash[:action]

            if WHITELISTED_GEO_ROUTES[controller]&.include?(action)
              ::Gitlab::Database.db_read_write?
            else
              WHITELISTED_GEO_ROUTES_TRACKING_DB[controller]&.include?(action)
            end
          end

          def geo_proxy_git_push_ssh_route
            routes = ::Gitlab::Middleware::ReadOnly::API_VERSIONS.map do |version|
              ["/api/v#{version}/geo/proxy_git_push_ssh/info_refs",
               "/api/v#{version}/geo/proxy_git_push_ssh/push"]
            end
            routes.flatten.include?(request.path)
          end
        end
      end
    end
  end
end
