# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class TokenLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          params = request.env[::API::Helpers::API_TOKEN_ENV]

          return {} unless params

          params.slice(:token_type, :token_id)
        end
      end
    end
  end
end
