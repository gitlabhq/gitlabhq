# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class JobsThreads
      @@jobs = {} # rubocop:disable Style/ClassVars
      MUTEX = Mutex.new

      def call(worker, job, queue)
        jid = job['jid']

        MUTEX.synchronize do
          @@jobs[jid] = Thread.current
        end

        return if self.class.cancelled?(jid)

        yield
      ensure
        MUTEX.synchronize do
          @@jobs.delete(jid)
        end
      end

      def self.interrupt(jid)
        MUTEX.synchronize do
          thread = @@jobs[jid]
          break unless thread

          thread.raise(Interrupt)
          thread
        end
      end

      def self.cancelled?(jid)
        Sidekiq.redis {|c| c.exists("cancelled-#{jid}") }
      end

      def self.mark_job_as_cancelled(jid)
        Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 86400, 1) }
        "Marked job as cancelled(if Sidekiq retry within 24 hours, the job will be skipped as `processed`). Jid: #{jid}"
      end

      def self.jobs
        @@jobs
      end
    end
  end
end
