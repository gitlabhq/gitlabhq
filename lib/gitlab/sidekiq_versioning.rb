module Gitlab
  module SidekiqVersioning
    def self.install!
      Sidekiq::Manager.prepend SidekiqVersioning::Manager
      Sidekiq::JobRetry.prepend SidekiqVersioning::JobRetry

      Sidekiq.server_middleware do |chain|
        chain.add SidekiqVersioning::Middleware
      end

      # We add all queues the application will listen on to the Sidekiq queue list,
      # including version queues, so that other Sidekiq processes can discover
      # version queues they should listen on (if they support the version) or
      # that they could requeue jobs on (if they don't).
      begin
        queues = queues_with_versions(SidekiqConfig.worker_queues)

        if queues.any?
          Sidekiq.redis do |conn|
            conn.pipelined do
              queues.each do |queue|
                conn.sadd('queues', queue)
              end
            end
          end
        end
      rescue ::Redis::BaseError, SocketError, Errno::ENOENT, Errno::EADDRNOTAVAIL, Errno::EAFNOSUPPORT, Errno::ECONNRESET, Errno::ECONNREFUSED
      end
    end

    def self.requeue_unsupported_job(worker, job, queue)
      job_version = job['version']
      return false unless job_version

      worker_version = worker&.class&.version

      Sidekiq.logger.info "job version: #{job_version}; worker version: #{worker_version || 'unknown'}"

      return false if worker&.support_job_version?

      if job['requeued_at']
        Sidekiq.logger.info "already requeued, not requeuing again"

        return false
      end

      job['original_queue'] = queue
      job['requeued_at'] = Time.now.to_f

      requeue_version = queue_versions(queue).select { |v| v >= job_version }.min || job_version
      job['queue'] = "#{queue}:v#{requeue_version}"

      Sidekiq::Client.push(job)
      Sidekiq.logger.info { "requeued on queue #{job['queue']}: #{job}" }

      true
    end

    def self.queues_with_versions(queues)
      queues.flat_map do |queue|
        SidekiqConfig.workers_by_queue[queue]&.supported_queues || queue
      end
    end

    def self.queue_versions(queue)
      SidekiqConfig.redis_queues.grep(/\A#{queue}:v([0-9]+)\z/) { $~[1].to_i }
    end
  end
end
