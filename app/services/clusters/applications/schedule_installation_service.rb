module Clusters
  module Applications
    class ScheduleInstallationService < ::BaseService
      def execute
        application = application_class.find_or_create_by!(cluster: cluster)

        application.make_scheduled!
        ClusterInstallAppWorker.perform_async(application.name, application.id)
        true
      rescue ActiveRecord::RecordInvalid
        false
      rescue StateMachines::InvalidTransition
        false
      end

      private

      def application_class
        params[:application_class]
      end

      def cluster
        params[:cluster]
      end
    end
  end
end
