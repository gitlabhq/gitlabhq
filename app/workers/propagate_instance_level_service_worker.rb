# frozen_string_literal: true

# Worker for updating any project specific caches.
class PropagateInstanceLevelServiceWorker
  include ApplicationWorker

  feature_category :source_code_management

  LEASE_TIMEOUT = 4.hours.to_i

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(instance_level_service_id)
    return unless try_obtain_lease_for(instance_level_service_id)

    Projects::PropagateInstanceLevelService.propagate(Service.find_by(id: instance_level_service_id))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def try_obtain_lease_for(instance_level_service_id)
    Gitlab::ExclusiveLease
      .new("propagate_instance_level_service_worker:#{instance_level_service_id}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end
end
