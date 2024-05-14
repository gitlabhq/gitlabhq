# frozen_string_literal: true

module Gitlab
  module SidekiqVersioning
    def self.install!
      # The Sidekiq client API always adds the queue to the Sidekiq queue
      # list, but mail_room and gitlab-shell do not. This is only necessary
      # for monitoring.
      queues = ::Gitlab::SidekiqConfig.routing_queues
      if queues.any?
        # Allow unrouted calls as this operation is idempotent and can be safely performed
        # by all Sidekiq processes
        SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq.redis do |conn|
            conn.multi do |multi|
              multi.del('queues')
              multi.sadd('queues', queues)
            end
          end
        end
      end
    rescue ::Redis::BaseError, SocketError, Errno::ENOENT, Errno::EADDRNOTAVAIL, Errno::EAFNOSUPPORT, Errno::ECONNRESET, Errno::ECONNREFUSED
    end
  end
end
