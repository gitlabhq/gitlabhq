module Geo
  module Scheduler
    class SchedulerWorker
      include ApplicationWorker
      include GeoQueue
      include ExclusiveLeaseGuard
      include ::Gitlab::Utils::StrongMemoize

      DB_RETRIEVE_BATCH_SIZE = 1000
      LEASE_TIMEOUT = 60.minutes
      RUN_TIME = 60.minutes.to_i

      attr_reader :pending_resources, :scheduled_jobs, :start_time, :loops

      def initialize
        @pending_resources = []
        @scheduled_jobs = []
      end

      # The scheduling works as the following:
      #
      # 1. Load a batch of IDs that we need to schedule (DB_RETRIEVE_BATCH_SIZE) into a pending list.
      # 2. Schedule them so that at most `max_capacity` are running at once.
      # 3. When a slot frees, schedule another job.
      # 4. When we have drained the pending list, load another batch into memory, and schedule the
      #    remaining jobs, excluding ones in progress.
      # 5. Quit when we have scheduled all jobs or exceeded MAX_RUNTIME.
      def perform
        @start_time = Time.now.utc
        @loops = 0

        # Prevent multiple Sidekiq workers from attempting to schedule jobs
        try_obtain_lease do
          log_info('Started scheduler')
          reason = :unknown

          begin
            reason = loop do
              break :node_disabled unless node_enabled?

              update_jobs_in_progress
              update_pending_resources

              break :over_time if over_time?
              break :complete unless resources_remain?

              # If we're still under the limit after refreshing from the DB, we
              # can end after scheduling the remaining transfers.
              last_batch = reload_queue?
              schedule_jobs
              @loops += 1

              break :last_batch if last_batch
              break :lease_lost unless renew_lease!

              sleep(1)
            end
          rescue => err
            reason = :error
            log_error(err.message)
            raise err
          ensure
            duration = Time.now.utc - start_time
            log_info('Finished scheduler', total_loops: loops, duration: duration, reason: reason)
          end
        end
      end

      private

      def worker_metadata
      end

      def db_retrieve_batch_size
        DB_RETRIEVE_BATCH_SIZE
      end

      def lease_timeout
        LEASE_TIMEOUT
      end

      def max_capacity
        raise NotImplementedError
      end

      def run_time
        RUN_TIME
      end

      def reload_queue?
        pending_resources.size < max_capacity
      end

      def resources_remain?
        !pending_resources.empty?
      end

      def over_time?
        (Time.now.utc - start_time) >= run_time
      end

      def take_batch(*arrays)
        interleave(*arrays).uniq.compact.take(db_retrieve_batch_size)
      end

      # Combines the elements of multiple, arbitrary-length arrays into a single array.
      #
      # Each array is spread evenly over the resultant array.
      # The order of the original arrays is preserved within the resultant array.
      # In the case of ties between elements, the element from the first array goes first.
      # From https://stackoverflow.com/questions/15628936/ruby-equally-distribute-elements-and-interleave-merge-multiple-arrays/15639147#15639147
      #
      # For examples, see the specs in file_download_dispatch_worker_spec.rb
      def interleave(*arrays)
        elements = []
        coefficients = []
        arrays.each_with_index do |e, index|
          elements += e
          coefficients += interleave_coefficients(e, index)
        end

        combined = elements.zip(coefficients)
        combined.sort_by { |zipped| zipped[1] }.map { |zipped| zipped[0] }
      end

      # Assigns a position to each element in order to spread out arrays evenly.
      #
      # `array_index` is used to resolve ties between arrays of equal length.
      #
      # Examples:
      #
      # irb(main):006:0> interleave_coefficients(['a', 'b'], 0)
      # => [0.2499998750000625, 0.7499996250001875]
      # irb(main):027:0> interleave_coefficients(['a', 'b', 'c'], 0)
      # => [0.16666661111112963, 0.4999998333333889, 0.8333330555556481]
      # irb(main):007:0> interleave_coefficients(['a', 'b', 'c'], 1)
      # => [0.16699994433335189, 0.5003331665556111, 0.8336663887778704]
      def interleave_coefficients(array, array_index)
        (1..array.size).map do |i|
          (i - 0.5 + array_index / 1000.0) / (array.size + 1e-6)
        end
      end

      def update_jobs_in_progress
        status = Gitlab::SidekiqStatus.job_status(scheduled_job_ids)

        # SidekiqStatus returns an array of booleans: true if the job is still running, false otherwise.
        # For each entry, first use `zip` to make { job_id: 123 } -> [ { job_id: 123 }, bool ]
        # Next, filter out the jobs that have completed.
        @scheduled_jobs = @scheduled_jobs.zip(status).map { |(job, running)| job if running }.compact
      end

      def update_pending_resources
        @pending_resources = load_pending_resources if reload_queue?
      end

      def schedule_jobs
        capacity = max_capacity
        num_to_schedule = [capacity - scheduled_job_ids.size, pending_resources.size].min
        num_to_schedule = 0 if num_to_schedule < 0

        to_schedule = pending_resources.shift(num_to_schedule)
        scheduled = to_schedule.map { |args| schedule_job(*args) }.compact
        scheduled_jobs.concat(scheduled)

        log_info("Loop #{loops}", enqueued: scheduled.length, pending: pending_resources.length, scheduled: scheduled_jobs.length, capacity: capacity)
      end

      def scheduled_job_ids
        scheduled_jobs.map { |data| data[:job_id] }
      end

      def current_node
        Gitlab::Geo.current_node
      end

      def node_enabled?
        # Only check every minute to avoid polling the DB excessively
        unless @last_enabled_check.present? && @last_enabled_check > 1.minute.ago
          @last_enabled_check = Time.now
          clear_memoization(:current_node_enabled)
        end

        strong_memoize(:current_node_enabled) do
          Gitlab::Geo.current_node_enabled?
        end
      end

      def log_info(message, extra_args = {})
        args = { class: self.class.name, message: message }.merge(extra_args)
        args.merge!(worker_metadata) if worker_metadata
        Gitlab::Geo::Logger.info(args)
      end

      def log_error(message, extra_args = {})
        args = { class: self.class.name, message: message }.merge(extra_args)
        args.merge!(worker_metadata) if worker_metadata
        Gitlab::Geo::Logger.error(args)
      end
    end
  end
end
