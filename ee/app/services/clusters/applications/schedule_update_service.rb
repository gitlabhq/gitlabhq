module Clusters
  module Applications
    class ScheduleUpdateService
      BACKOFF_DELAY = 2.minutes

      attr_accessor :application, :project

      def initialize(application, project)
        @application = application
        @project = project
      end

      def execute
        return unless application

        if recently_scheduled?
          worker_class.perform_in(BACKOFF_DELAY, application.name, application.id, project.id, Time.now)
        else
          worker_class.perform_async(application.name, application.id, project.id, Time.now)
        end
      end

      private

      def worker_class
        ::ClusterUpdateAppWorker
      end

      def recently_scheduled?
        return false unless application.last_update_started_at

        application.last_update_started_at.utc >= Time.now.utc - BACKOFF_DELAY
      end
    end
  end
end
