# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Formatters
      class LogrageWithTimestamp
        include Gitlab::EncodingHelper

        def call(severity, datetime, _, data)
          time = data.delete :time
          data[:params] = process_params(data)

          attributes = {
            time: datetime.utc.iso8601(3),
            severity: severity,
            duration: time[:total],
            db: time[:db],
            view: time[:view]
          }.merge(data)
          ::Lograge.formatter.call(attributes) + "\n"
        end

        private

        def process_params(data)
          return [] unless data.has_key?(:params)

          data[:params]
            .each_pair
            .map { |k, v| { key: k, value: utf8_encode_values(v) } }
        end

        def utf8_encode_values(data)
          case data
          when Hash
            data.merge(data) { |k, v| utf8_encode_values(v) }
          when Array
            data.map { |v| utf8_encode_values(v) }
          when String
            encode_utf8(data)
          end
        end
      end
    end
  end
end
