# frozen_string_literal: true

module Clusters
  module Applications
    class ScheduleInstallationService < ::BaseService
      def execute(application)
        application.make_scheduled!

        ClusterInstallAppWorker.perform_async(application.name, application.id)
      end
    end
  end
end
