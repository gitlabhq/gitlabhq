module Clusters
  class CheckAppInstallationProgressService < BaseHelmService
    def execute
      return unless app.installing?

      FetchAppInstallationStatusService.new(app).execute do |phase, log|
        case phase
        when 'Succeeded'
          if app.make_installed
            FinalizeAppInstallationService.new(app).execute
          else
            app.make_errored!("Failed to update app record; #{app.errors}")
          end
        when 'Failed'
          app.make_errored!(log || 'Installation silently failed')
          FinalizeAppInstallationService.new(app).execute
        else
          if Time.now.utc - app.updated_at.to_time.utc > ClusterWaitForAppInstallationWorker::TIMEOUT
            app.make_errored!('App installation timeouted')
          else
            ClusterWaitForAppInstallationWorker.perform_in(
              ClusterWaitForAppInstallationWorker::EAGER_INTERVAL, app.name, app.id)
          end
        end
      end
    end
  end
end
