module Clusters
  module Applications
    class FinalizeInstallationService < BaseHelmService
      def execute
        helm_api.delete_installation_pod!(app)

        app.make_installed! if app.installing?
      end
    end
  end
end
