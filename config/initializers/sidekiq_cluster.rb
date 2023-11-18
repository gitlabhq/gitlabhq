# frozen_string_literal: true

if ENV['ENABLE_SIDEKIQ_CLUSTER']
  Thread.new do
    Thread.current.abort_on_exception = true

    parent = Process.ppid

    loop do
      sleep(5)

      next if Process.ppid == parent

      # In cluster mode it's possible that the master process is SIGKILL'd. In
      # this case the parent PID changes and we need to terminate ourselves.

      Process.kill(:TERM, Process.pid)

      # Allow sidekiq to cleanly terminate and push any running jobs back
      # into the queue.  We use the configured timeout and add a small
      # grace period
      sleep(Sidekiq.default_configuration[:timeout] + 5)

      # Signaling the Sidekiq Pgroup as KILL is not forwarded to
      # a possible child process. In Sidekiq Cluster, all child Sidekiq
      # processes are PGROUP leaders (each process has its own pgroup).
      Process.kill(:KILL, 0)
      break
    end
  end
end
