module Gitlab
  # JobWaiter can be used to wait for a number of Sidekiq jobs to complete.
  class JobWaiter
    # The sleep interval between checking keys, in seconds.
    INTERVAL = 0.1

    # jobs - The job IDs to wait for.
    def initialize(jobs)
      @jobs = jobs
    end

    # Waits for all the jobs to be completed.
    #
    # timeout - The maximum amount of seconds to block the caller for. This
    #           ensures we don't indefinitely block a caller in case a job takes
    #           long to process, or is never processed.
    def wait(timeout = 60)
      start = Time.current

      while (Time.current - start) <= timeout
        break if SidekiqStatus.all_completed?(@jobs)

        sleep(INTERVAL) # to not overload Redis too much.
      end
    end
  end
end
