require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    class SidekiqMetricsExporter < Daemon
      def enabled?
        Gitlab::Metrics.metrics_folder_present? && settings.enabled
      end

      def settings
        Settings.monitoring.sidekiq_exporter
      end

      private

      attr_reader :server

      def start_working
        @server = ::WEBrick::HTTPServer.new(Port: settings.port, BindAddress: settings.address)
        server.mount "/", Rack::Handler::WEBrick, rack_app
        server.start
      end

      def stop_working
        server.shutdown if server
        @server = nil
      end

      def rack_app
        Rack::Builder.app do
          use Rack::Deflater
          use ::Prometheus::Client::Rack::Exporter
          run -> (env) { [404, {}, ['']] }
        end
      end
    end
  end
end
