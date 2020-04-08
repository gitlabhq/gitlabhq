# frozen_string_literal: true

if ENV['ENABLE_SIDEKIQ_CLUSTER']
  Thread.new do
    Thread.current.abort_on_exception = true

    parent = Process.ppid

    loop do
      sleep(5)

      # In cluster mode it's possible that the master process is SIGKILL'd. In
      # this case the parent PID changes and we need to terminate ourselves.
      if Process.ppid != parent
        Process.kill(:TERM, Process.pid)

        # Wait for just a few extra seconds for a final attempt to
        # gracefully terminate. Considering the parent (cluster) process
        # have changed (SIGKILL'd), it shouldn't take long to shutdown.
        sleep(5)

        # Signaling the Sidekiq Pgroup as KILL is not forwarded to
        # a possible child process. In Sidekiq Cluster, all child Sidekiq
        # processes are PGROUP leaders (each process has its own pgroup).
        Process.kill(:KILL, 0)
        break
      end
    end
  end
end
