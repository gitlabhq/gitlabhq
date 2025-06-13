# frozen_string_literal: true

require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    module Exporter
      class BaseExporter < Daemon
        CERT_REGEX = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/

        attr_reader :server

        # @param settings [Hash] SettingsLogic hash containing the `*_exporter` config
        # @param log_enabled [Boolean] whether to log HTTP requests
        # @param log_file [String] path to where the server log should be located
        # @param gc_requests [Boolean] whether to run a major GC after each scraper request
        def initialize(settings, log_enabled:, log_file:, gc_requests: false, **options)
          super(**options)

          @settings = settings
          @gc_requests = gc_requests

          # log_enabled does not exist for all exporters
          log_sink = log_enabled ? File.join(Rails.root, 'log', log_file) : File::NULL
          @logger = WEBrick::Log.new(log_sink)
          @logger.time_format = "[%Y-%m-%dT%H:%M:%S.%L%z]"
        end

        def enabled?
          settings.enabled
        end

        private

        attr_reader :settings, :logger

        def start_working
          access_log = [
            [logger, WEBrick::AccessLog::COMBINED_LOG_FORMAT]
          ]

          server_config = {
            Port: settings.port,
            BindAddress: settings.address,
            Logger: logger,
            AccessLog: access_log
          }

          server_config.merge!(ssl_config) if settings['tls_enabled']

          @server = ::WEBrick::HTTPServer.new(server_config)
          server.mount '/', Rack::Handler::WEBrick, rack_app

          true
        rescue StandardError => e
          logger.error(e)
          false
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
            server.listeners.each(&:close) unless thread.alive?
            server.shutdown
          end

          @server = nil
        end

        def rack_app
          pid = thread_name
          gc_requests = @gc_requests

          Rack::Builder.app do
            use Rack::Deflater
            use Gitlab::Metrics::Exporter::MetricsMiddleware, pid
            use Gitlab::Metrics::Exporter::GcRequestMiddleware if gc_requests
            use ::Prometheus::Client::Rack::Exporter if ::Gitlab::Metrics.metrics_folder_present?
            run ->(env) { [404, {}, ['']] }
          end
        end

        def ssl_config
          # This monkey-patches WEBrick::GenericServer, so never require this unless TLS is enabled.
          require 'webrick/ssl'

          certs = load_ca_certs_bundle(File.binread(settings['tls_cert_path']))

          {
            SSLEnable: true,
            SSLCertificate: certs.shift,
            SSLPrivateKey: OpenSSL::PKey.read(File.binread(settings['tls_key_path'])),
            # SSLStartImmediately is true by default according to the docs, but when WEBrick creates the
            # SSLServer internally, the switch was always nil for some reason. Setting this explicitly fixes this.
            SSLStartImmediately: true,
            SSLExtraChainCert: certs
          }
        end

        # In Ruby OpenSSL v3.0.0, this can be replaced by OpenSSL::X509::Certificate.load
        # https://github.com/ruby/openssl/issues/254
        def load_ca_certs_bundle(ca_certs_string)
          return [] unless ca_certs_string

          ca_certs_string.scan(CERT_REGEX).map do |ca_cert_string|
            OpenSSL::X509::Certificate.new(ca_cert_string)
          end
        end
      end
    end
  end
end
