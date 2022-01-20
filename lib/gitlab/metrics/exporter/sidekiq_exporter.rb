# frozen_string_literal: true

module Gitlab
  module Metrics
    module Exporter
      class SidekiqExporter < BaseExporter
        def initialize(settings, **options)
          super(settings,
            log_enabled: settings['log_enabled'],
            log_file: 'sidekiq_exporter.log',
            **options)
        end
      end
    end
  end
end
