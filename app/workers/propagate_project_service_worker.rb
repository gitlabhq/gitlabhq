# Worker for updating any project specific caches.
class PropagateProjectServiceWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  LEASE_TIMEOUT = 30.minutes.to_i

  def perform(template_id)
    template = Service.find_by(id: template_id)

    return unless template&.active
    return unless try_obtain_lease_for(template.id)

    Rails.logger.info("Propagating services for template #{template.id}")

    project_ids_for_template(template) do |project_id|
      Service.build_from_template(project_id, template).save!
    end
  end

  private

  def project_ids_for_template(template)
    limit = 100
    offset = 0

    loop do
      batch = project_ids_batch(limit, offset, template.type)

      batch.each { |project_id| yield(project_id) }

      break if batch.count < limit

      offset += limit
    end
  end

  def project_ids_batch(limit, offset, template_type)
    Project.joins('LEFT JOIN services ON services.project_id = projects.id').
      where('services.type != ? OR services.id IS NULL', template_type).
      limit(limit).offset(offset).pluck(:id)
  end

  def try_obtain_lease_for(template_id)
    Gitlab::ExclusiveLease.
      new("propagate_project_service_worker:#{template_id}", timeout: LEASE_TIMEOUT).
      try_obtain
  end
end
