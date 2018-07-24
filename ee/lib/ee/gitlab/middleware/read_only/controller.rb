module EE
  module Gitlab
    module Middleware
      module ReadOnly
        module Controller
          extend ::Gitlab::Utils::Override

          WHITELISTED_GEO_ROUTES = {
            'admin/geo_nodes' => %w{update}
          }.freeze

          private

          override :whitelisted_routes
          def whitelisted_routes
            super || geo_node_update_route
          end

          def geo_node_update_route
            # Calling route_hash may be expensive. Only do it if we think there's a possible match
            return false unless request.path =~ %r{/admin/geo_nodes}

            ::Gitlab::Database.db_read_write? &&
              WHITELISTED_GEO_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
          end
        end
      end
    end
  end
end
