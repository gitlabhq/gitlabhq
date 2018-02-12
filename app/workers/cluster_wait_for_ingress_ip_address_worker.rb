class ClusterWaitForIngressIpAddressWorker
  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  INTERVAL = 10.seconds
  TIMEOUT = 20.minutes

  def perform(app_name, app_id, retries_remaining)
    find_application(app_name, app_id) do |app|
      Clusters::Applications::CheckIngressIpAddressService.new(app).execute(retries_remaining)
    end
  end
end
