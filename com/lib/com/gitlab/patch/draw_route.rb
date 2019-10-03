# frozen_string_literal: true

module Com
  module Gitlab
    module Patch
      module DrawRoute
        extend ::Gitlab::Utils::Override

        override :draw_com
        def draw_com(routes_name)
          draw_route(route_path("com/config/routes/#{routes_name}.rb"))
        end
      end
    end
  end
end
