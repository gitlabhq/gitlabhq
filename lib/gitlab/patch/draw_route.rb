# frozen_string_literal: true

# We're patching `ActionDispatch::Routing::Mapper` in
# config/initializers/routing_draw.rb
module Gitlab
  module Patch
    module DrawRoute
      RoutesNotFound = Class.new(StandardError)

      def draw(routes_name)
        draw_ce(routes_name) | draw_ee(routes_name) ||
          raise(RoutesNotFound.new("Cannot find #{routes_name}"))
      end

      def draw_ce(routes_name)
        draw_route(Rails.root.join("config/routes/#{routes_name}.rb"))
      end

      def draw_ee(routes_name)
        draw_route(Rails.root.join("ee/config/routes/#{routes_name}.rb"))
      end

      def draw_route(path)
        if File.exist?(path)
          instance_eval(File.read(path))
          true
        else
          false
        end
      end
    end
  end
end
