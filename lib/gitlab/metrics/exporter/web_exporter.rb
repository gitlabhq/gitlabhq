# frozen_string_literal: true

module Gitlab
  module Metrics
    module Exporter
      class WebExporter < BaseExporter
        RailsMetricsInitializer = Struct.new(:app) do
          def call(env)
            Gitlab::Metrics::RailsSlis.initialize_request_slis_if_needed!

            app.call(env)
          end
        end

        # This exporter is always run on master process
        def initialize(**options)
          super(Settings.monitoring.web_exporter, log_enabled: true, log_file: 'web_exporter.log', **options)
        end

        private

        def rack_app
          app = super

          Rack::Builder.app do
            use RailsMetricsInitializer
            run app
          end
        end
      end
    end
  end
end
