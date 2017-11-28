module Gitlab
  module SidekiqVersioning
    def self.install!
      Sidekiq::Manager.prepend SidekiqVersioning::Manager

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
