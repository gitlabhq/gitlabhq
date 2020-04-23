# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class ExceptionLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, response_body)
          data = {}
          data[:api_error] = format_body(response_body) if bad_request?(request)

          # grape-logging attempts to pass the logger the exception
          # (https://github.com/aserafin/grape_logging/blob/v1.7.0/lib/grape_logging/middleware/request_logger.rb#L63),
          # but it appears that the rescue_all in api.rb takes
          # precedence so the logger never sees it. We need to
          # store and retrieve the exception from the environment.
          exception = request.env[::API::Helpers::API_EXCEPTION_ENV]

          return data unless exception.is_a?(Exception)

          Gitlab::ExceptionLogFormatter.format!(exception, data)

          data
        end

        private

        def format_body(response_body)
          # https://github.com/rack/rack/blob/master/SPEC.rdoc#label-The+Body:
          # The response_body must respond to each, but just in case we
          # guard against errors here.
          response_body = Array(response_body) unless response_body.respond_to?(:each)

          # To avoid conflicting types in Elasticsearch, convert every
          # element into an Array of strings. A response body is usually
          # an array of Strings so that the response can be sent in
          # chunks.
          body = []
          # each_with_object doesn't work with Rack::BodyProxy
          response_body.each { |chunk| body << chunk.to_s }
          body
        end

        def bad_request?(request)
          request.env[::API::Helpers::API_RESPONSE_STATUS_CODE] == 400
        end
      end
    end
  end
end
