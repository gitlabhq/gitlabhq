# frozen_string_literal: true

require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    module Exporter
      class WebExporter < BaseExporter
        ExporterCheck = Struct.new(:exporter) do
          def readiness
            Gitlab::HealthChecks::Result.new(
              'web_exporter', exporter.running)
          end
        end

        attr_reader :running

        # This exporter is always run on master process
        def initialize
          super

          self.readiness_checks = [
            WebExporter::ExporterCheck.new(self),
            Gitlab::HealthChecks::PumaCheck,
            Gitlab::HealthChecks::UnicornCheck
          ]
        end

        def settings
          Gitlab.config.monitoring.web_exporter
        end

        def log_filename
          File.join(Rails.root, 'log', 'web_exporter.log')
        end

        private

        def start_working
          @running = true
          super
        end

        def stop_working
          @running = false
          wait_in_blackout_period if server && thread.alive?
          super
        end

        def wait_in_blackout_period
          return unless blackout_seconds > 0

          @server.logger.info(
            message: 'starting blackout...',
            duration_s: blackout_seconds)

          sleep(blackout_seconds)
        end

        def blackout_seconds
          settings['blackout_seconds'].to_i
        end
      end
    end
  end
end
