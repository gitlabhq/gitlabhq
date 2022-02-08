# frozen_string_literal: true

module Gitlab
  module Metrics
    module Exporter
      class WebExporter < BaseExporter
        # This exporter is always run on master process
        def initialize(**options)
          super(Settings.monitoring.web_exporter, log_enabled: true, log_file: 'web_exporter.log', **options)
        end
      end
    end
  end
end
