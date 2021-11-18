# frozen_string_literal: true

module Gitlab
  module Metrics
    module Exporter
      class SidekiqExporter < BaseExporter
        def settings
          Settings.monitoring.sidekiq_exporter
        end

        def log_filename
          if settings['log_enabled']
            File.join(Rails.root, 'log', 'sidekiq_exporter.log')
          else
            File::NULL
          end
        end
      end
    end
  end
end
