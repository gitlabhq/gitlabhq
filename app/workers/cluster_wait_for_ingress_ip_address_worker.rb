class ClusterWaitForIngressIpAddressWorker
  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  INTERVAL = 10.seconds

  def perform(app_name, app_id, retries_remaining)
    find_application(app_name, app_id) do |app|
      result = Clusters::Applications::CheckIngressIpAddressService.new(app).execute
      retry_if_necessary(app_name, app_id, retries_remaining) unless result
    end
  rescue Clusters::Applications::CheckIngressIpAddressService::Error => e
    retry_if_necessary(app_name, app_id, retries_remaining)
    raise e
  end

  private

  def retry_if_necessary(app_name, app_id, retries_remaining)
    if retries_remaining > 0
      self.class.perform_in(INTERVAL, app_name, app_id, retries_remaining - 1)
    end
  end
end
