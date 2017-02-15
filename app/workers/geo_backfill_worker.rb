class GeoBackfillWorker
  include Sidekiq::Worker
  include CronjobQueue

  RUN_TIME = 5.minutes.to_i.freeze

  def perform
    start = Time.now

    project_ids.each do |project_id|
      break if Time.now - start >= RUN_TIME

      project = Project.find(project_id)
      next if project.repository_exists?

      try_obtain_lease do
        Geo::RepositoryBackfillService.new(project).execute
      end
    end
  end

  private

  def project_ids
    return [] if Project.count == Geo::ProjectRegistry.count

    Project.where.not(id: Geo::ProjectRegistry.pluck(:id))
           .limit(100)
           .pluck(:id)
  end

  def try_obtain_lease
    uuid = Gitlab::ExclusiveLease.new(
      lease_key,
      timeout: 24.hours
    ).try_obtain

    return unless uuid

    yield

    release_lease(uuid)
  end

  def release_lease(uuid)
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end

  def lease_key
    'repository_backfill_service'
  end
end
