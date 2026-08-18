# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class TruncateParameters < ::GrapeLogging::Loggers::Base
        include Gitlab::EncodingHelper

        # Matches the sentinel emitted by Gitlab::Lograge::CustomOptions so
        # truncated Grape and Rails logs look the same.
        TRUNCATION_SENTINEL_KEY = 'truncated'
        TRUNCATION_SENTINEL_VALUE = '...'
        MAXIMUM_ARRAY_LENGTH = Gitlab::Utils::LogLimitedArray::MAXIMUM_ARRAY_LENGTH

        def parameters(request, _)
          return {} unless request.params

          truncated_params = {}
          estimator = Gitlab::Utils::JsonSizeEstimator.new(max_size: MAXIMUM_ARRAY_LENGTH)

          request.params.each do |key, value|
            # Estimate the raw value first so a single huge parameter aborts
            # early (mid-traversal) without us allocating an encoded copy of it.
            begin
              estimator.estimate([key, value])
            rescue Gitlab::Utils::JsonSizeEstimator::SizeExceededError
              truncated_params[TRUNCATION_SENTINEL_KEY] = TRUNCATION_SENTINEL_VALUE
              break
            end

            truncated_params[key] = utf8_encode_values(value)
          end

          # grape_logging builds this payload after the endpoint has run, so
          # replacing the params only affects what we log. Truncating here (before
          # FilterParameters) avoids running the parameter filter regexes over
          # very large payloads.
          request.params.replace(truncated_params)

          {}
        end

        private

        def utf8_encode_values(data)
          case data
          when Hash
            data.merge!(data) { |_k, v| utf8_encode_values(v) }
          when Array
            data.map! { |v| utf8_encode_values(v) }
          when String
            encode_utf8(data)
          else
            data
          end
        end
      end
    end
  end
end
