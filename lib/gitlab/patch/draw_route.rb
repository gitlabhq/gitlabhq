# frozen_string_literal: true

# We're patching `ActionDispatch::Routing::Mapper` in
# config/initializers/routing_draw.rb
module Gitlab
  module Patch
    module DrawRoute
      def draw(routes_name)
        instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))

        draw_ee(routes_name)
      end

      def draw_ee(routes_name)
        path = Rails.root.join("ee/config/routes/#{routes_name}.rb")

        instance_eval(File.read(path)) if File.exist?(path)
      end
    end
  end
end
