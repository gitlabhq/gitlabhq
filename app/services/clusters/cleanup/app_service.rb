# frozen_string_literal: true

module Clusters
  module Cleanup
    class AppService < Clusters::Cleanup::BaseService
      def execute
        persisted_applications = @cluster.persisted_applications

        persisted_applications.each do |app|
          next unless app.available?
          next unless app.can_uninstall?

          log_event(:uninstalling_app, application: app.class.application_name)
          uninstall_app_async(app)
        end

        # Keep calling the worker untill all dependencies are uninstalled
        return schedule_next_execution(Clusters::Cleanup::AppWorker) if persisted_applications.any?

        log_event(:schedule_remove_project_namespaces)
        cluster.continue_cleanup!
      end

      private

      def uninstall_app_async(application)
        application.make_scheduled!

        Clusters::Applications::UninstallWorker.perform_async(application.name, application.id)
      end
    end
  end
end
