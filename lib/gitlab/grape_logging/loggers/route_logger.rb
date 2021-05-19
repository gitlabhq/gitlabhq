# frozen_string_literal: true

# This grape_logging module (https://github.com/aserafin/grape_logging) makes it
# possible to log the details of the action
module Gitlab
  module GrapeLogging
    module Loggers
      class RouteLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          endpoint = request.env[Grape::Env::API_ENDPOINT]
          route = endpoint&.route&.pattern&.origin

          return {} unless route

          { route: route }
        rescue StandardError
          # endpoint.route calls env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
          # but env[Grape::Env::GRAPE_ROUTING_ARGS] is nil in the case of a 405 response
          # so we're rescuing exceptions and bailing out
          {}
        end
      end
    end
  end
end
