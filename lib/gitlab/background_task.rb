# frozen_string_literal: true

module Gitlab
  # Used to run small workloads concurrently to other threads in the current process.
  # This may be necessary when accessing process state, which cannot be done via
  # Sidekiq jobs.
  #
  # Since the given task is put on its own thread, use instances sparingly and only
  # for fast computations since they will compete with other threads such as Puma
  # or Sidekiq workers for CPU time and memory.
  #
  # Good examples:
  # - Polling and updating process counters
  # - Observing process or thread state
  # - Enforcing process limits at the application level
  #
  # Bad examples:
  # - Running database queries
  # - Running CPU bound work loads
  #
  # As a guideline, aim to yield frequently if tasks execute logic in loops by
  # making each iteration cheap. If life-cycle callbacks like start and stop
  # aren't necessary and the task does not loop, consider just using Thread.new.
  #
  # rubocop: disable Gitlab/NamespacedClass
  class BackgroundTask
    AlreadyStartedError = Class.new(StandardError)

    attr_reader :name

    def running?
      @state == :running
    end

    # Possible options:
    # - name [String] used to identify the task in thread listings and logs (defaults to 'background_task')
    # - synchronous [Boolean] if true, turns `start` into a blocking call
    def initialize(task, **options)
      @task = task
      @synchronous = options[:synchronous]
      @name = options[:name] || self.class.name.demodulize.underscore
      # We use a monitor, not a Mutex, because monitors allow for re-entrant locking.
      @mutex = ::Monitor.new
      @state = :idle
    end

    def start
      @mutex.synchronize do
        raise AlreadyStartedError, "background task #{name} already running on #{@thread}" if running?

        start_task = @task.respond_to?(:start) ? @task.start : true

        if start_task
          @state = :running

          at_exit { stop }

          @thread = Thread.new do
            Thread.current.name = name
            @task.call
          end

          @thread.join if @synchronous
        end
      end

      self
    end

    def stop
      @mutex.synchronize do
        break unless running?

        if @thread
          # If thread is not in a stopped state, interrupt it because it may be sleeping.
          # This is so we process a stop signal ASAP.
          @thread.wakeup if @thread.alive?
          begin
            # Propagate stop event if supported.
            @task.stop if @task.respond_to?(:stop)

            # join will rethrow any error raised on the background thread
            @thread.join unless Thread.current == @thread
          rescue Exception => ex # rubocop:disable Lint/RescueException
            Gitlab::ErrorTracking.track_exception(ex, extra: { reported_by: name })
          end
          @thread = nil
        end

        @state = :stopped
      end
    end
  end
  # rubocop: enable Gitlab/NamespacedClass
end
