# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class ExceptionLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          # grape-logging attempts to pass the logger the exception
          # (https://github.com/aserafin/grape_logging/blob/v1.7.0/lib/grape_logging/middleware/request_logger.rb#L63),
          # but it appears that the rescue_all in api.rb takes
          # precedence so the logger never sees it. We need to
          # store and retrieve the exception from the environment.
          exception = request.env[::API::Helpers::API_EXCEPTION_ENV]
          data = {}

          return data unless exception.is_a?(Exception)

          Gitlab::ExceptionLogFormatter.format!(exception, data)

          data
        end
      end
    end
  end
end
