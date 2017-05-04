# Worker for updating any project specific caches.
class PropagateProjectServiceWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  sidekiq_options retry: 3

  LEASE_TIMEOUT = 4.hours.to_i

  def perform(template_id)
    return unless try_obtain_lease_for(template_id)

    Projects::PropagateService.propagate(Service.find_by(id: template_id))
  end

  private

  def try_obtain_lease_for(template_id)
    Gitlab::ExclusiveLease.
      new("propagate_project_service_worker:#{template_id}", timeout: LEASE_TIMEOUT).
      try_obtain
  end
end
