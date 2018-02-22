class ClusterWaitForIngressIpAddressWorker
  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  INTERVAL = 30.seconds

  def perform(app_name, app_id, retries_remaining)
    find_application(app_name, app_id) do |app|
      Clusters::Applications::CheckIngressIpAddressService.new(app).execute
    end
  end
end
