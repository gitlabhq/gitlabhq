# This grape_logging module (https://github.com/aserafin/grape_logging) makes it
# possible to log the user who performed the Grape API action by retrieving
# the user context from the request environment.
module Gitlab
  module GrapeLogging
    module Loggers
      class UserLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          params = request.env[::API::Helpers::API_USER_ENV]

          return {} unless params

          params.slice(:user_id, :username)
        end
      end
    end
  end
end
