class ClusterWaitForAppInstallationWorker
  include Sidekiq::Worker
  include ClusterQueue
  include ClusterApp

  INITIAL_INTERVAL = 30.seconds
  EAGER_INTERVAL = 10.seconds
  TIMEOUT = 20.minutes

  def perform(app_name, app_id)
    find_app(app_name, app_id) do |app|
      Clusters::FetchAppInstallationStatusService.new(app).execute do |phase, log|
        case phase
        when 'Succeeded'
          if app.make_installed
            Clusters::FinalizeAppInstallationService.new(app).execute
          else
            app.make_errored!("Failed to update app record; #{app.errors}")
          end
        when 'Failed'
          app.make_errored!(log || 'Installation silently failed')
          Clusters::FinalizeAppInstallationService.new(app).execute
        else
          if Time.now.utc - app.updated_at.to_time.utc > TIMEOUT
            app.make_errored!('App installation timeouted')
          else
            ClusterWaitForAppInstallationWorker.perform_in(EAGER_INTERVAL, app.name, app.id)
          end
        end
      end
    end
  end
end
