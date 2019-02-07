# frozen_string_literal: true

module Clusters
  module Applications
    class ScheduleInstallationService
      attr_reader :application

      def initialize(application)
        @application = application
      end

      def execute
        application.updateable? ? schedule_upgrade : schedule_install
      end

      private

      def schedule_upgrade
        application.make_scheduled!

        ClusterUpgradeAppWorker.perform_async(application.name, application.id)
      end

      def schedule_install
        application.make_scheduled!

        ClusterInstallAppWorker.perform_async(application.name, application.id)
      end
    end
  end
end
