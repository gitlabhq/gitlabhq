module Gitlab
  module GrapeLogging
    module Formatters
      class LogrageWithTimestamp
        include Gitlab::EncodingHelper

        def call(severity, datetime, _, data)
          time = data.delete :time
          data[:params] = utf8_encode_values(data[:params]) if data.has_key?(:params)

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
