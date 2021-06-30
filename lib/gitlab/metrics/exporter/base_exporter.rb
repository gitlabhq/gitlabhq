# frozen_string_literal: true

require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    module Exporter
      class BaseExporter < Daemon
        attr_reader :server

        attr_accessor :readiness_checks

        def enabled?
          settings.enabled
        end

        def settings
          raise NotImplementedError
        end

        def log_filename
          raise NotImplementedError
        end

        private

        def start_working
          logger = WEBrick::Log.new(log_filename)
          logger.time_format = "[%Y-%m-%dT%H:%M:%S.%L%z]"

          access_log = [
            [logger, WEBrick::AccessLog::COMBINED_LOG_FORMAT]
          ]

          @server = ::WEBrick::HTTPServer.new(
            Port: settings.port, BindAddress: settings.address,
            Logger: logger, AccessLog: access_log)
          server.mount_proc '/readiness' do |req, res|
            render_probe(readiness_probe, req, res)
          end
          server.mount_proc '/liveness' do |req, res|
            render_probe(liveness_probe, req, res)
          end
          server.mount '/', Rack::Handler::WEBrick, rack_app

          true
        end

        def run_thread
          server&.start
        rescue IOError
          # ignore forcibily closed servers
        end

        def stop_working
          if server
            # we close sockets if thread is not longer running
            # this happens, when the process forks
            if thread.alive?
              server.shutdown
            else
              server.listeners.each(&:close)
            end
          end

          @server = nil
        end

        def rack_app
          Rack::Builder.app do
            use Rack::Deflater
            use ::Prometheus::Client::Rack::Exporter if ::Gitlab::Metrics.metrics_folder_present?
            run -> (env) { [404, {}, ['']] }
          end
        end

        def readiness_probe
          ::Gitlab::HealthChecks::Probes::Collection.new(*readiness_checks)
        end

        def liveness_probe
          ::Gitlab::HealthChecks::Probes::Collection.new
        end

        def render_probe(probe, req, res)
          result = probe.execute

          res.status = result.http_status
          res.content_type = 'application/json; charset=utf-8'
          res.body = result.json.to_json
        end
      end
    end
  end
end
