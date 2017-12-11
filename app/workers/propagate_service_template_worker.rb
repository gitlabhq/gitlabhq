# Worker for updating any project specific caches.
class PropagateServiceTemplateWorker
  include ApplicationWorker

  LEASE_TIMEOUT = 4.hours.to_i

  def perform(template_id)
    return unless try_obtain_lease_for(template_id)

    Projects::PropagateServiceTemplate.propagate(Service.find_by(id: template_id))
  end

  private

  def try_obtain_lease_for(template_id)
    Gitlab::ExclusiveLease
      .new("propagate_service_template_worker:#{template_id}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end
end
