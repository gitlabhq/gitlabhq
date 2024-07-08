# frozen_string_literal: true

# trigger stackprof by sending a SIGUSR2 signal
#
# Docs: https://docs.gitlab.com/ee/development/performance.html#production

module Gitlab
  class StackProf
    DEFAULT_FILE_PREFIX = Dir.tmpdir
    DEFAULT_TIMEOUT_SEC = 30
    DEFAULT_MODE = :cpu
    # Sample interval as a frequency in microseconds (~99hz); appropriate for CPU profiles
    DEFAULT_INTERVAL_US = 10_100
    # Sample interval in event occurrences (n = every nth event); appropriate for allocation profiles
    DEFAULT_INTERVAL_EVENTS = 100

    # this is a workaround for sidekiq, which defines its own SIGUSR2 handler.
    # by defering to the sidekiq startup event, we get to set up our own
    # handler late enough.
    # see also: https://github.com/mperham/sidekiq/pull/4653
    def self.install
      require 'stackprof'
      require 'tmpdir'

      if Gitlab::Runtime.sidekiq?
        Sidekiq.configure_server do |config|
          config.on :startup do
            on_worker_start
          end
        end
      else
        Gitlab::Cluster::LifecycleEvents.on_worker_start do
          on_worker_start
        end
      end
    end

    def self.on_worker_start
      log_event('listening for SIGUSR2 signal')

      # create a pipe in order to propagate signal out of the signal handler
      # see also: https://cr.yp.to/docs/selfpipe.html
      read, write = IO.pipe

      # create a separate thread that polls for signals on the pipe.
      #
      # this way we do not execute in signal handler context, which
      # lifts restrictions and also serializes the calls in a thread-safe
      # manner.
      #
      # it's very similar to a goroutine and channel design.
      #
      # another nice benefit of this method is that we can timeout the
      # IO.wait_readable call, allowing the profile to automatically stop after
      # a given interval (by default 30 seconds), avoiding unbounded memory
      # growth from a profile that was started and never stopped.
      t = Thread.new do
        timeout_s = ENV['STACKPROF_TIMEOUT_S']&.to_i || DEFAULT_TIMEOUT_SEC
        current_timeout_s = nil
        loop do
          read.getbyte if read.wait_readable(current_timeout_s)

          if ::StackProf.running?
            stackprof_file_prefix = ENV['STACKPROF_FILE_PREFIX'] || DEFAULT_FILE_PREFIX
            stackprof_out_file = "#{stackprof_file_prefix}/stackprof.#{Process.pid}.#{SecureRandom.hex(6)}.profile"

            log_event(
              'stopping profile',
              profile_filename: stackprof_out_file,
              profile_timeout_s: timeout_s
            )

            ::StackProf.stop
            ::StackProf.results(stackprof_out_file)
            current_timeout_s = nil
          else
            mode = ENV['STACKPROF_MODE']&.to_sym || DEFAULT_MODE
            stackprof_interval = ENV['STACKPROF_INTERVAL']&.to_i
            stackprof_interval ||= interval(mode)

            log_event(
              'starting profile',
              profile_mode: mode,
              profile_interval: stackprof_interval,
              profile_timeout: timeout_s
            )

            ::StackProf.start(
              mode: mode,
              raw: Gitlab::Utils.to_boolean(ENV['STACKPROF_RAW'] || 'true'),
              interval: stackprof_interval
            )
            current_timeout_s = timeout_s
          end
        end
      rescue StandardError => e
        log_event("stackprof failed: #{e}")
      end
      t.abort_on_exception = true

      # in the case of puma, this will override the existing SIGUSR2 signal handler
      # that can be used to trigger a restart.
      #
      # puma cluster has two types of restarts:
      # * SIGUSR1: phased restart
      # * SIGUSR2: restart
      #
      # phased restart is not supported in our configuration, because we use
      # preload_app. this means we will always perform a normal restart.
      # additionally, phased restart is not supported when sending a SIGUSR2
      # directly to a puma worker (as opposed to the master process).
      #
      # the result is that the behaviour of SIGUSR1 and SIGUSR2 is identical in
      # our configuration, and we can always use a SIGUSR1 to perform a restart.
      #
      # thus, it is acceptable for us to re-appropriate the SIGUSR2 signal, and
      # override the puma behaviour.
      #
      # see also:
      # * https://github.com/puma/puma/blob/master/docs/signals.md#puma-signals
      # * https://github.com/mperham/sidekiq/wiki/Signals
      Signal.trap('SIGUSR2') do
        write.write('.')
      end
    end

    def self.log_event(event, labels = {})
      Gitlab::AppJsonLogger.info({
        event: 'stackprof',
        message: event,
        pid: Process.pid
      }.merge(labels.compact))
    end

    def self.interval(mode)
      mode == :object ? DEFAULT_INTERVAL_EVENTS : DEFAULT_INTERVAL_US
    end
  end
end
