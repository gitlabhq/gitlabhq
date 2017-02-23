class GeoBackfillWorker
  include Sidekiq::Worker
  include CronjobQueue

  RUN_TIME = 5.minutes.to_i.freeze

  def perform
    start = Time.now
    project_ids = find_project_ids

    logger.info "Started Geo backfilling for #{project_ids.length} project(s)"

    project_ids.each do |project_id|
      break if Time.now - start >= RUN_TIME
      break unless node_enabled?

      project = Project.find(project_id)
      next if project.repository_exists?

      try_obtain_lease do |lease|
        GeoSingleRepositoryBackfillWorker.new.perform(project_id, lease)
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
    lease = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

    return unless lease

    yield lease
  end

  def lease_key
    Geo::RepositoryBackfillService::LEASE_KEY_PREFIX
  end

  def lease_timeout
    Geo::RepositoryBackfillService::LEASE_TIMEOUT
  end

  def node_enabled?
    # No caching of the enabled! If we cache it and an admin disables
    # this node, an active GeoBackfillWorker would keep going for up
    # to max run time after the node was disabled.
    Gitlab::Geo.current_node.enabled?
  end
end
