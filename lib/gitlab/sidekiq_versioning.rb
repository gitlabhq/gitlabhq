module Gitlab
  module SidekiqVersioning
    def self.install!
      Sidekiq::Manager.prepend SidekiqVersioning::Manager

      # The Sidekiq client API always adds the queue to the Sidekiq queue
      # list, but mail_room and gitlab-shell do not. This is only necessary
      # for monitoring.
      begin
        queues = SidekiqConfig.worker_queues

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
  end
end
