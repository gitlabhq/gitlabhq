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
            'admin/geo_nodes' => %w{resync recheck force_redownload}
          }.freeze

          private

          override :whitelisted_routes
          def whitelisted_routes
            super || geo_node_update_route
          end

          def geo_node_update_route
            # Calling route_hash may be expensive. Only do it if we think there's a possible match
            return false unless request.path =~ %r{/admin/geo_nodes}

            controller = route_hash[:controller]
            action = route_hash[:action]

            if WHITELISTED_GEO_ROUTES[controller]&.include?(action)
              return ::Gitlab::Database.db_read_write?
            end

            WHITELISTED_GEO_ROUTES_TRACKING_DB[controller]&.include?(action)
          end
        end
      end
    end
  end
end
