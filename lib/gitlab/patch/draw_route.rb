# frozen_string_literal: true

# We're patching `ActionDispatch::Routing::Mapper` in
# config/initializers/routing_draw.rb
module Gitlab
  module Patch
    module DrawRoute
      RoutesNotFound = Class.new(StandardError)

      def draw(routes_name)
        drawn_any = draw_ee(routes_name) | draw_ce(routes_name)

        drawn_any || raise(RoutesNotFound, "Cannot find #{routes_name}")
      end

      def draw_ce(routes_name)
        draw_route(route_path("config/routes/#{routes_name}.rb"))
      end

      def draw_ee(_)
        true
      end

      def route_path(routes_name)
        Rails.root.join(routes_name)
      end

      def draw_route(path)
        if File.exist?(path)
          instance_eval(File.read(path), path.to_s)
          true
        else
          false
        end
      end
    end
  end
end

Gitlab::Patch::DrawRoute.prepend_mod_with('Gitlab::Patch::DrawRoute')
