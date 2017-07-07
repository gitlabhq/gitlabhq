class GeoRepositorySyncWorker
  include Sidekiq::Worker
  include CronjobQueue

  LEASE_KEY = 'geo_repository_sync_worker'.freeze
  LEASE_TIMEOUT = 8.hours.freeze
  BATCH_SIZE = 1000
  BACKOFF_DELAY = 5.minutes
  MAX_CAPACITY = 25
  RUN_TIME = 60.minutes.to_i

  def initialize
    @pending_projects = []
    @scheduled_jobs = []
  end

  def perform
    return unless Gitlab::Geo.secondary_role_enabled?
    return unless Gitlab::Geo.primary_node.present?

    logger.info "Started Geo repository sync scheduler"

    @start_time = Time.now

    # Prevent multiple Sidekiq workers from attempting to schedule projects synchronization
    try_obtain_lease do
      loop do
        break unless node_enabled?

        update_jobs_in_progress
        load_pending_projects if reload_queue?

        # If we are still under the limit after refreshing our DB, we can end
        # after scheduling the remaining transfers.
        last_batch = reload_queue?

        break if over_time?
        break unless projects_remain?

        schedule_jobs

        break if last_batch

        sleep(1)
      end

      logger.info "Finished Geo repository sync scheduler"
    end
  end

  private

  def reload_queue?
    @pending_projects.size < MAX_CAPACITY
  end

  def projects_remain?
    @pending_projects.size > 0
  end

  def over_time?
    Time.now - @start_time >= RUN_TIME
  end

  def load_pending_projects
    project_ids_not_synced = find_project_ids_not_synced
    project_ids_updated_recently = find_project_ids_updated_recently

    @pending_projects = interleave(project_ids_not_synced, project_ids_updated_recently)
  end

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

  def schedule_jobs
    num_to_schedule = [MAX_CAPACITY - scheduled_job_ids.size, @pending_projects.size].min
    return unless projects_remain?

    num_to_schedule.times do
      project_id = @pending_projects.shift
      job_id = Geo::ProjectSyncWorker.perform_in(BACKOFF_DELAY, project_id, Time.now)

      if job_id
        @scheduled_jobs << { id: project_id, job_id: job_id }
      end
    end
  end

  def scheduled_job_ids
    @scheduled_jobs.map { |data| data[:job_id] }
  end

  def update_jobs_in_progress
    status = Gitlab::SidekiqStatus.job_status(scheduled_job_ids)

    # SidekiqStatus returns an array of booleans: true if the job has completed, false otherwise.
    # For each entry, first use `zip` to make { job_id: 123, id: 10 } -> [ { job_id: 123, id: 10 }, bool ]
    # Next, filter out the jobs that have completed.
    @scheduled_jobs = @scheduled_jobs.zip(status).map { |(job, completed)| job if completed }.compact
  end

  def try_obtain_lease
    lease = Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT).try_obtain

    return unless lease

    begin
      yield lease
    ensure
      Gitlab::ExclusiveLease.cancel(LEASE_KEY, lease)
    end
  end

  def release_lease(uuid)
    Gitlab::ExclusiveLease.cancel(LEASE_KEY, uuid)
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
