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

        private

        # Sidekiq Exporter does not work properly in sidekiq-cluster
        # mode. It tries to start the service on the same port for
        # each of the cluster workers, this results in failure
        # due to duplicate binding.
        #
        # For now we ignore this error, as metrics are still "kind of"
        # valid as they are rendered from shared directory.
        #
        # Issue: https://gitlab.com/gitlab-org/gitlab/issues/5714
        def start_working
          super
        rescue Errno::EADDRINUSE => e
          Sidekiq.logger.error(
            class: self.class.to_s,
            message: 'Cannot start sidekiq_exporter',
            'exception.message' => e.message
          )

          false
        end
      end
    end
  end
end
