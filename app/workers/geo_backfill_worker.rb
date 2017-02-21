class GeoBackfillWorker
  include Sidekiq::Worker
  include CronjobQueue

  LEASE_TIMEOUT = 8.hours.freeze
  RUN_TIME      = 5.minutes.to_i.freeze

  def perform
    start = Time.now
    project_ids = find_project_ids

    logger.info "Started Geo backfilling for #{project_ids.length} project(s)"

    project_ids.each do |project_id|
      break if Time.now - start >= RUN_TIME
      break unless node_enabled?

      project = Project.find(project_id)
      next if project.repository_exists?

      try_obtain_lease do
        Geo::RepositoryBackfillService.new(project).execute
      end
    end

    logger.info "Finished Geo backfilling for #{project_ids.length} project(s)"
  end

  private

  def find_project_ids
    return [] if Project.count == Geo::ProjectRegistry.count

    Project.where.not(id: Geo::ProjectRegistry.pluck(:id))
           .limit(100)
           .pluck(:id)
  end

  def try_obtain_lease
    uuid = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

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

  def node_enabled?
    # No caching of the enabled! If we cache it and an admin disables
    # this node, an active GeoBackfillWorker would keep going for up
    # to max run time after the node was disabled.
    Gitlab::Geo.current_node.enabled?
  end
end
