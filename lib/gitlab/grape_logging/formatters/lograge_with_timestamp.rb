# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Formatters
      class LogrageWithTimestamp
        include Gitlab::EncodingHelper

        EMPTY_ARRAY = [].freeze

        def call(severity, datetime, _, data)
          time = data.delete :time
          data[:params] = process_params(data)

          attributes = {
            time: datetime.utc.iso8601(3),
            severity: severity,
            duration_s: Gitlab::Utils.ms_to_round_sec(time[:total]),
            db_duration_s: Gitlab::Utils.ms_to_round_sec(time[:db]),
            view_duration_s: Gitlab::Utils.ms_to_round_sec(time[:view])
          }.merge!(data)

          ::Lograge.formatter.call(attributes) << "\n"
        end

        private

        def process_params(data)
          return EMPTY_ARRAY unless data.has_key?(:params)

          params_array = data[:params].map { |k, v| { key: k, value: utf8_encode_values(v) } }

          Gitlab::Utils::LogLimitedArray.log_limited_array(params_array, sentinel: Gitlab::Lograge::CustomOptions::LIMITED_ARRAY_SENTINEL)
        end

        def utf8_encode_values(data)
          case data
          when Hash
            data.merge!(data) { |k, v| utf8_encode_values(v) }
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
