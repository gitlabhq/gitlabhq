# frozen_string_literal: true

require_relative "draw_all/version"

module ActionDispatch
  module DrawAll
    RoutesNotFound = Class.new(StandardError)

    # Draws all matching files located inside the config/routes directories
    def draw_all(routes_name)
      drawn_any = false

      Rails.application.config.paths['config/routes'].paths.each do |path|
        route_path = path.join("#{routes_name}.rb")

        drawn_any |= draw_route(route_path)
      end

      return if drawn_any

      msg  = "Your router tried to #draw_all the external file #{routes_name}.rb,\n" \
        "but the file was not found in:\n\n"
      msg += Rails.application.config.paths['config/routes']
        .paths
        .map { |path| " * #{path}" }.join("\n")

      raise RoutesNotFound, msg
    end

    private

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

ActionDispatch::Routing::Mapper.prepend ActionDispatch::DrawAll
