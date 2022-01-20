# frozen_string_literal: true

module Gitlab
  module Metrics
    module Exporter
      class WebExporter < BaseExporter
        ExporterCheck = Struct.new(:exporter) do
          def readiness
            Gitlab::HealthChecks::Result.new(
              'web_exporter', exporter.running)
          end

          def available?
            true
          end
        end

        RailsMetricsInitializer = Struct.new(:app) do
          def call(env)
            Gitlab::Metrics::RailsSlis.initialize_request_slis_if_needed!

            app.call(env)
          end
        end

        attr_reader :running

        # This exporter is always run on master process
        def initialize(**options)
          super(Settings.monitoring.web_exporter, log_enabled: true, log_file: 'web_exporter.log', **options)

          # DEPRECATED:
          # these `readiness_checks` are deprecated
          # as presenting no value in a way how we run
          # application: https://gitlab.com/gitlab-org/gitlab/issues/35343
          self.readiness_checks = [
            WebExporter::ExporterCheck.new(self),
            Gitlab::HealthChecks::PumaCheck
          ]
        end

        def mark_as_not_running!
          @running = false
        end

        private

        def rack_app
          app = super

          Rack::Builder.app do
            use RailsMetricsInitializer
            run app
          end
        end

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
