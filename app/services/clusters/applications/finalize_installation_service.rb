module Clusters
  module Applications
    class FinalizeInstallationService < BaseHelmService
      def execute
        helm_api.delete_installation_pod!(app)

        app.make_errored!('Installation aborted') if aborted?
      end

      private

      def aborted?
        app.installing? || app.scheduled?
      end
    end
  end
end
