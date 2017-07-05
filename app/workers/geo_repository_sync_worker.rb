class GeoRepositorySyncWorker
  include Sidekiq::Worker
  include CronjobQueue

  RUN_TIME = 5.minutes.to_i
  BATCH_SIZE = 100
  BACKOFF_DELAY = 5.minutes

  def perform
    return unless Gitlab::Geo.secondary_role_enabled?
    return unless Gitlab::Geo.primary_node.present?

    start_time = Time.now
    project_ids_not_synced = find_project_ids_not_synced
    project_ids_updated_recently = find_project_ids_updated_recently
    project_ids = interleave(project_ids_not_synced, project_ids_updated_recently)

    logger.info "Started Geo repository syncing for #{project_ids.length} project(s)"

    project_ids.each do |project_id|
      break if over_time?(start_time)
      break unless node_enabled?

      Geo::ProjectSyncWorker.perform_in(BACKOFF_DELAY, project_id, Time.now)
    end

    logger.info "Finished Geo repository syncing for #{project_ids.length} project(s)"
  end

  private

  def find_project_ids_not_synced
    Project.where.not(id: Geo::ProjectRegistry.synced.pluck(:project_id))
           .order(last_repository_updated_at: :desc)
           .limit(BATCH_SIZE)
           .pluck(:id)
  end

  def find_project_ids_updated_recently
    Geo::ProjectRegistry.dirty
                        .order(Gitlab::Database.nulls_first_order(:last_repository_synced_at, :desc))
                        .limit(BATCH_SIZE)
                        .pluck(:project_id)
  end

  def interleave(first, second)
    if first.length >= second.length
      first.zip(second)
    else
      second.zip(first).map(&:reverse)
    end.flatten(1).uniq.compact.take(BATCH_SIZE)
  end

  def over_time?(start_time)
    Time.now - start_time >= RUN_TIME
  end

  def node_enabled?
    # Only check every minute to avoid polling the DB excessively
    unless @last_enabled_check.present? && @last_enabled_check > 1.minute.ago
      @last_enabled_check = Time.now
      @current_node_enabled = nil
    end

    @current_node_enabled ||= Gitlab::Geo.current_node_enabled?
  end
end
