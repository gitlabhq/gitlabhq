# frozen_string_literal: true

require "cgi"

module Gitlab
  module Tracing
    class Factory
      OPENTRACING_SCHEME = "opentracing"

      def self.create_tracer(service_name, connection_string)
        return unless connection_string.present?

        begin
          opentracing_details = parse_connection_string(connection_string)
          driver_name = opentracing_details[:driver_name]

          case driver_name
          when "jaeger"
            JaegerFactory.create_tracer(service_name, opentracing_details[:options])
          else
            raise "Unknown driver: #{driver_name}"
          end
        rescue => e
          # Can't create the tracer? Warn and continue sans tracer
          warn "Unable to instantiate tracer: #{e}"
          nil
        end
      end

      def self.parse_connection_string(connection_string)
        parsed = URI.parse(connection_string)

        unless valid_uri?(parsed)
          raise "Invalid tracing connection string"
        end

        {
          driver_name: parsed.host,
          options: parse_query(parsed.query)
        }
      end
      private_class_method :parse_connection_string

      def self.parse_query(query)
        return {} unless query

        CGI.parse(query).symbolize_keys.transform_values(&:first)
      end
      private_class_method :parse_query

      def self.valid_uri?(uri)
        return false unless uri

        uri.scheme == OPENTRACING_SCHEME &&
          uri.host.to_s =~ /^[a-z0-9_]+$/ &&
          uri.path.empty?
      end
      private_class_method :valid_uri?
    end
  end
end
