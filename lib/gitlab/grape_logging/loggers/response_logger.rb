# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class ResponseLogger < ::GrapeLogging::Loggers::Base
        def parameters(_, response)
          return {} unless Feature.enabled?(:log_response_length)

          response_bytes = 0
          response.each { |resp| response_bytes += resp.to_s.bytesize }
          {
            response_bytes: response_bytes
          }
        end
      end
    end
  end
end
