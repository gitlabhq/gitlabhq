module Geo
  class BaseSchedulerWorker
    include Sidekiq::Worker
    include CronjobQueue

    DB_RETRIEVE_BATCH_SIZE = 1000
    LEASE_TIMEOUT = 60.minutes
    MAX_CAPACITY = 10
    RUN_TIME = 60.minutes.to_i

    attr_reader :pending_resources, :scheduled_jobs, :start_time

    def initialize
      @pending_resources = []
      @scheduled_jobs = []
    end

    # The scheduling works as the following:
    #
    # 1. Load a batch of IDs that we need to schedule (DB_RETRIEVE_BATCH_SIZE) into a pending list.
    # 2. Schedule them so that at most MAX_CAPACITY are running at once.
    # 3. When a slot frees, schedule another job.
    # 4. When we have drained the pending list, load another batch into memory, and schedule the
    #    remaining jobs, excluding ones in progress.
    # 5. Quit when we have scheduled all jobs or exceeded MAX_RUNTIME.
    def perform
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?

      log_info('Started scheduler')

      @start_time = Time.now

      # Prevent multiple Sidekiq workers from attempting to schedule jobs
      try_obtain_lease do
        loop do
          break unless node_enabled?

          update_jobs_in_progress
          @pending_resources = load_pending_resources if reload_queue?

          # If we are still under the limit after refreshing our DB, we can end
          # after scheduling the remaining transfers.
          last_batch = reload_queue?

          break if over_time?
          break unless resources_remain?

          schedule_jobs

          break if last_batch
          break unless renew_lease!

          sleep(1)
        end

        log_info('Finished scheduler')
      end
    end

    private

    def db_retrieve_batch_size
      DB_RETRIEVE_BATCH_SIZE
    end

    def lease_key
      @lease_key ||= self.class.name.underscore
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def max_capacity
      MAX_CAPACITY
    end

    def run_time
      RUN_TIME
    end

    def reload_queue?
      pending_resources.size < max_capacity
    end

    def resources_remain?
      pending_resources.size > 0
    end

    def over_time?
      Time.now - start_time >= run_time
    end

    def interleave(first, second)
      if first.length >= second.length
        first.zip(second)
      else
        second.zip(first).map(&:reverse)
      end.flatten(1).uniq.compact.take(db_retrieve_batch_size)
    end

    def update_jobs_in_progress
      status = Gitlab::SidekiqStatus.job_status(scheduled_job_ids)

      # SidekiqStatus returns an array of booleans: true if the job has completed, false otherwise.
      # For each entry, first use `zip` to make { job_id: 123, id: 10 } -> [ { job_id: 123, id: 10 }, bool ]
      # Next, filter out the jobs that have completed.
      @scheduled_jobs = @scheduled_jobs.zip(status).map { |(job, completed)| job if completed }.compact
    end

    def schedule_jobs
      num_to_schedule = [max_capacity - scheduled_job_ids.size, pending_resources.size].min

      return unless resources_remain?

      num_to_schedule.times do
        job = schedule_job(*pending_resources.shift)
        scheduled_jobs << job if job&.fetch(:job_id).present?
      end
    end

    def scheduled_job_ids
      scheduled_jobs.map { |data| data[:job_id] }
    end

    def try_obtain_lease
      lease = exclusive_lease.try_obtain

      unless lease
        log_error('Cannot obtain an exclusive lease. There must be another worker already in execution.')
        return
      end

      begin
        yield lease
      ensure
        release_lease(lease)
      end
    end

    def exclusive_lease
      @lease ||= Gitlab::ExclusiveLease.new(lease_key, timeout: lease_timeout)
    end

    def renew_lease!
      exclusive_lease.renew
    end

    def release_lease(uuid)
      Gitlab::ExclusiveLease.cancel(lease_key, uuid)
    end

    def node_enabled?
      # Only check every minute to avoid polling the DB excessively
      unless @last_enabled_check.present? && @last_enabled_check > 1.minute.ago
        @last_enabled_check = Time.now
        @current_node_enabled = nil
      end

      @current_node_enabled ||= Gitlab::Geo.current_node_enabled?
    end

    def log_info(message)
      Gitlab::Geo::Logger.info(class: self.class.name, message: message)
    end

    def log_error(message)
      Gitlab::Geo::Logger.error(class: self.class.name, message: message)
    end
  end
end
