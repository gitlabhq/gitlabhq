# frozen_string_literal: true

# DEPRECATED: To be removed as part of https://gitlab.com/groups/gitlab-org/-/epics/5877
module Clusters
  module Applications
    class ScheduleUpdateService
      BACKOFF_DELAY = 2.minutes

      attr_accessor :application, :project

      def initialize(cluster_prometheus_adapter, project)
        @application = cluster_prometheus_adapter&.cluster&.application_prometheus
        @project = project
      end

      def execute
        return unless application
        return if application.externally_installed?

        if recently_scheduled?
          worker_class.perform_in(BACKOFF_DELAY, application.name, application.id, project.id, Time.current)
        else
          worker_class.perform_async(application.name, application.id, project.id, Time.current)
        end
      end

      private

      def worker_class
        ::ClusterUpdateAppWorker
      end

      def recently_scheduled?
        return false unless application.last_update_started_at

        application.last_update_started_at.utc >= Time.current.utc - BACKOFF_DELAY
      end
    end
  end
end
