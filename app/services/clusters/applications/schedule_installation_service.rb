# frozen_string_literal: true

module Clusters
  module Applications
    class ScheduleInstallationService
      attr_reader :application

      def initialize(application)
        @application = application
      end

      def execute
        application.make_scheduled!

        ClusterInstallAppWorker.perform_async(application.name, application.id)
      end
    end
  end
end
