class GeoFileDownloadDispatchWorker
  include Sidekiq::Worker
  include CronjobQueue

  LEASE_KEY = 'geo_file_download_dispatch_worker'.freeze
  LEASE_TIMEOUT = 8.hours.freeze
  RUN_TIME = 60.minutes.to_i.freeze
  DB_RETRIEVE_BATCH = 1000.freeze
  MAX_CONCURRENT_DOWNLOADS = 10.freeze

  def initialize
    @pending_downloads = []
    @scheduled_jobs = []
  end

  # The scheduling works as the following:
  #
  # 1. Load a batch of IDs that we need to download from the primary (DB_RETRIEVE_BATCH) into a pending list.
  # 2. Schedule them so that at most MAX_CONCURRENT_DOWNLOADS are running at once.
  # 3. When a slot frees, schedule another download.
  # 4. When we have drained the pending list, load another batch into memory, and schedule the remaining
  #    files, excluding ones in progress.
  # 5. Quit when we have scheduled all downloads or exceeded an hour.
  def perform
    return unless Gitlab::Geo.configured?
    return unless Gitlab::Geo.secondary?

    @start_time = Time.now

    # Prevent multiple Sidekiq workers from attempting to schedule downloads
    try_obtain_lease do
      loop do
        break unless node_enabled?

        update_jobs_in_progress
        load_pending_downloads if reload_queue?

        # If we are still under the limit after refreshing our DB, we can end
        # after scheduling the remaining transfers.
        last_batch = reload_queue?

        break if over_time?
        break unless downloads_remain?

        schedule_downloads

        break if last_batch

        sleep(1)
      end
    end
  end

  private

  def reload_queue?
    @pending_downloads.size < MAX_CONCURRENT_DOWNLOADS
  end

  def over_time?
    Time.now - @start_time >= RUN_TIME
  end

  def load_pending_downloads
    lfs_object_ids = find_lfs_object_ids(DB_RETRIEVE_BATCH)
    objects_ids    = find_object_ids(DB_RETRIEVE_BATCH)

    @pending_downloads = interleave(lfs_object_ids, objects_ids)
  end

  def interleave(first, second)
    if first.length >= second.length
      first.zip(second)
    else
      second.zip(first).map(&:reverse)
    end.flatten(1).compact.take(DB_RETRIEVE_BATCH)
  end

  def downloads_remain?
    @pending_downloads.size
  end

  def schedule_downloads
    num_to_schedule = [MAX_CONCURRENT_DOWNLOADS - job_ids.size, @pending_downloads.size].min

    return unless downloads_remain?

    num_to_schedule.times do
      object_db_id, object_type = @pending_downloads.shift
      job_id = GeoFileDownloadWorker.perform_async(object_type, object_db_id)

      if job_id
        @scheduled_jobs << { id: object_db_id, type: object_type, job_id: job_id }
      end
    end
  end

  def find_object_ids(limit)
    downloaded_ids = find_downloaded_ids([:attachment, :avatar, :file])

    Upload.where.not(id: downloaded_ids)
          .order(created_at: :desc)
          .limit(limit)
          .pluck(:id, :uploader)
          .map { |id, uploader| [id, uploader.sub(/Uploader\z/, '').downcase] }
  end

  def find_lfs_object_ids(limit)
    downloaded_ids = find_downloaded_ids([:lfs])

    LfsObject.where.not(id: downloaded_ids)
             .order(created_at: :desc)
             .limit(limit)
             .pluck(:id)
             .map { |id| [id, :lfs] }
  end

  def find_downloaded_ids(file_types)
    downloaded_ids = Geo::FileRegistry.where(file_type: file_types).pluck(:file_id)
    (downloaded_ids + scheduled_ids(file_types)).uniq
  end

  def update_jobs_in_progress
    status = Gitlab::SidekiqStatus.job_status(job_ids)

    # SidekiqStatus returns an array of booleans: true if the job has completed, false otherwise.
    # For each entry, first use `zip` to make { job_id: 123, id: 10 } -> [ { job_id: 123, id: 10 }, bool ]
    # Next, filter out the jobs that have completed.
    @scheduled_jobs = @scheduled_jobs.zip(status).map { |(job, completed)| job if completed }.compact
  end

  def job_ids
    @scheduled_jobs.map { |data| data[:job_id] }
  end

  def scheduled_ids(types)
    @scheduled_jobs.select { |data| types.include?(data[:type]) }.map { |data| data[:id] }
  end

  def try_obtain_lease
    uuid = Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT).try_obtain

    return unless uuid

    yield

    release_lease(uuid)
  end

  def release_lease(uuid)
    Gitlab::ExclusiveLease.cancel(LEASE_KEY, uuid)
  end

  def node_enabled?
    # Only check every minute to avoid polling the DB excessively
    unless @last_enabled_check.present? && (Time.now - @last_enabled_check > 1.minute)
      @last_enabled_check = Time.now
      @current_node_enabled = nil
    end

    @current_node_enabled ||= Gitlab::Geo.current_node_enabled?
  end
end
