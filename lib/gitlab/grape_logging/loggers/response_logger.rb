# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class ResponseLogger < ::GrapeLogging::Loggers::Base
        def parameters(_, response)
          return {} unless Feature.enabled?(:log_response_length)

          response_bytes = 0

          case response
          when String
            response_bytes = response.bytesize
          else
            response.each { |resp| response_bytes += resp.to_s.bytesize }
          end

          {
            response_bytes: response_bytes
          }
        end
      end
    end
  end
end
