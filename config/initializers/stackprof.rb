# frozen_string_literal: true

# trigger stackprof by sending a SIGUSR2 signal
#
# default settings:
# * collect raw samples
# * sample at 100hz (every 10k microseconds)
# * timeout profile after 30 seconds
# * write to $TMPDIR/stackprof.$PID.$RAND.profile

if Gitlab::Utils.to_boolean(ENV['STACKPROF_ENABLED'].to_s)
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    require 'stackprof'
    require 'tmpdir'

    Gitlab::AppJsonLogger.info "stackprof: listening on SIGUSR2 signal"

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
    # IO.select call, allowing the profile to automatically stop after
    # a given interval (by default 30 seconds), avoiding unbounded memory
    # growth from a profile that was started and never stopped.
    t = Thread.new do
      timeout_s = ENV['STACKPROF_TIMEOUT_S']&.to_i || 30
      current_timeout_s = nil
      loop do
        got_value = IO.select([read], nil, nil, current_timeout_s)
        read.getbyte if got_value

        if StackProf.running?
          stackprof_file_prefix = ENV['STACKPROF_FILE_PREFIX'] || Dir.tmpdir
          stackprof_out_file = "#{stackprof_file_prefix}/stackprof.#{Process.pid}.#{SecureRandom.hex(6)}.profile"

          Gitlab::AppJsonLogger.info(
            event: "stackprof",
            message: "stopping profile",
            output_filename: stackprof_out_file,
            pid: Process.pid,
            timeout_s: timeout_s,
            timed_out: got_value.nil?
          )

          StackProf.stop
          StackProf.results(stackprof_out_file)
          current_timeout_s = nil
        else
          Gitlab::AppJsonLogger.info(
            event: "stackprof",
            message: "starting profile",
            pid: Process.pid
          )

          StackProf.start(
            mode: :cpu,
            raw: Gitlab::Utils.to_boolean(ENV['STACKPROF_RAW'] || 'true'),
            interval: ENV['STACKPROF_INTERVAL_US']&.to_i || 10_000
          )
          current_timeout_s = timeout_s
        end
      end
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
    # * https://github.com/phusion/unicorn/blob/master/SIGNALS
    # * https://github.com/mperham/sidekiq/wiki/Signals
    Signal.trap('SIGUSR2') do
      write.write('.')
    end
  end
end
