class ClusterWaitForIngressIpAddressWorker
  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  def perform(app_name, app_id)
    find_application(app_name, app_id) do |app|
      Clusters::Applications::CheckIngressIpAddressService.new(app).execute
    end
  end
end
