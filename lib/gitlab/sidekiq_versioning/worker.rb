module Gitlab
  module SidekiqVersioning
    module Worker
      extend ActiveSupport::Concern

      included do
        version 0

        attr_accessor :job_version
      end

      module ClassMethods
        def version(new_version = nil)
          if new_version
            sidekiq_options version: new_version.to_i
          else
            get_sidekiq_options['version']
          end
        end

        def supported_queues
          @supported_queues ||= supported_versions.map { |v| "#{queue}:v#{v}" } << queue
        end

        private

        def queue_versions
          @queue_versions ||= SidekiqVersioning.queue_versions(queue)
        end

        def supported_versions
          return [] unless version

          queue_versions.select { |v| v < version } << version
        end
      end

      def support_job_version?(job_version = self.job_version)
        job_version <= self.class.version
      end
    end
  end
end
