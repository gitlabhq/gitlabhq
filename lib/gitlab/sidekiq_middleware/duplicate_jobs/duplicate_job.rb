# frozen_string_literal: true

require 'digest'

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      # This class defines an identifier of a job in a queue
      # The identifier based on a job's class and arguments.
      #
      # As strategy decides when to keep track of the job in redis and when to
      # remove it.
      #
      # Storing the deduplication key in redis can be done by calling `check!`
      # check returns the `jid` of the job if it was scheduled, or the `jid` of
      # the duplicate job if it was already scheduled
      #
      # When new jobs can be scheduled again, the strategy calls `#delete`.
      class DuplicateJob
        DUPLICATE_KEY_TTL = 6.hours

        attr_reader :existing_jid

        def initialize(job, queue_name, strategy: :until_executing)
          @job = job
          @queue_name = queue_name
          @strategy = strategy
        end

        # This will continue the middleware chain if the job should be scheduled
        # It will return false if the job needs to be cancelled
        def schedule(&block)
          Strategies.for(strategy).new(self).schedule(job, &block)
        end

        # This will continue the server middleware chain if the job should be
        # executed.
        # It will return false if the job should not be executed.
        def perform(&block)
          Strategies.for(strategy).new(self).perform(job, &block)
        end

        # This method will return the jid that was set in redis
        def check!
          read_jid = nil

          Sidekiq.redis do |redis|
            redis.multi do |multi|
              redis.set(idempotency_key, jid, ex: DUPLICATE_KEY_TTL, nx: true)
              read_jid = redis.get(idempotency_key)
            end
          end

          self.existing_jid = read_jid.value
        end

        def delete!
          Sidekiq.redis do |redis|
            redis.del(idempotency_key)
          end
        end

        def duplicate?
          raise "Call `#check!` first to check for existing duplicates" unless existing_jid

          jid != existing_jid
        end

        def droppable?
          idempotent? && duplicate?
        end

        private

        attr_reader :queue_name, :strategy, :job
        attr_writer :existing_jid

        def worker_class_name
          job['class']
        end

        def arguments
          job['args']
        end

        def jid
          job['jid']
        end

        def idempotency_key
          @idempotency_key ||= "#{namespace}:#{idempotency_hash}"
        end

        def idempotency_hash
          Digest::SHA256.hexdigest(idempotency_string)
        end

        def namespace
          "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:duplicate:#{queue_name}"
        end

        def idempotency_string
          "#{worker_class_name}:#{arguments.join('-')}"
        end

        def idempotent?
          worker_class = worker_class_name.to_s.safe_constantize
          return false unless worker_class
          return false unless worker_class.respond_to?(:idempotent?)

          worker_class.idempotent?
        end
      end
    end
  end
end
