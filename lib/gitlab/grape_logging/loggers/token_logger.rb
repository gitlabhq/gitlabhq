# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class TokenLogger < ::GrapeLogging::Loggers::Base
        def parameters(_request, _)
          params = ::Current.token_info

          return {} unless params

          params.slice(:token_type, :token_id)
        end
      end
    end
  end
end
