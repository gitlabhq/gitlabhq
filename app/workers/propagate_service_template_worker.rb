# frozen_string_literal: true

# Worker for updating any project specific caches.
class PropagateServiceTemplateWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  LEASE_TIMEOUT = 4.hours.to_i

  def perform(template_id)
    try_obtain_lease_for(template_id) do
      Projects::PropagateServiceTemplate.propagate(Service.find_by(id: template_id))
    end
  rescue LeaseNotObtained
  end

  private

  def lease_timeout
    LEASE_TIMEOUT
  end
end
