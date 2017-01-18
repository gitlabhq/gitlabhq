if ENV['ENABLE_SIDEKIQ_CLUSTER']
  # Throttling should be disabled for dedicated workers.
  module Gitlab
    class SidekiqThrottler
      def self.execute!
      end
    end
  end

  Thread.new do
    Thread.current.abort_on_exception = true

    parent = Process.ppid

    loop do
      sleep(5)

      # In cluster mode it's possible that the master process is SIGKILL'd. In
      # this case the parent PID changes and we need to terminate ourselves.
      if Process.ppid != parent
        Process.kill(:TERM, Process.pid)
        break
      end
    end
  end
end
