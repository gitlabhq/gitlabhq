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

          # DEPRECATED:
          # these `readiness_checks` are deprecated
          # as presenting no value in a way how we run
          # application: https://gitlab.com/gitlab-org/gitlab/issues/35343
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

        def mark_as_not_running!
          @running = false
        end

        private

        def start_working
          @running = true
          super
        end

        def stop_working
          mark_as_not_running!
          super
        end
      end
    end
  end
end
