# frozen_string_literal: true

module Clusters
  module Applications
    class ScheduleInstallationService
      attr_accessor :current_user, :params

      def initialize(user = nil, params = {})
        @current_user, @params = user, params.dup
      end

      def execute(application)
        application.make_scheduled!

        ClusterInstallAppWorker.perform_async(application.name, application.id)
      end
    end
  end
end
