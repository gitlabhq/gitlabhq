module Clusters
  class FinalizeAppInstallationService < BaseHelmService
    def execute
      helm.delete_installation_pod!(app)

      app.make_errored!('Installation aborted') if aborted?
    end

    private

    def aborted?
      app.installing? || app.scheduled?
    end
  end
end
