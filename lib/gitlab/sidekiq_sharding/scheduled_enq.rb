# frozen_string_literal: true

module Gitlab
  module SidekiqSharding
    class ScheduledEnq < ::Sidekiq::Scheduled::Enq
      # This class replaces Sidekiq::Client within Sidekiq::Scheduled::Enq
      # as it implements only a .push method which is used in Enq.
      # This minimises the surface area of the patch to just .push.
      class ScheduledEnqClient
        def initialize(container)
          @config = container
          @client = Sidekiq::Client.new(config: container)
        end

        def push(job_hash)
          return @client.push(job_hash) unless Gitlab::SidekiqSharding::Router.enabled?

          job_class = job_hash["class"].to_s.safe_constantize
          store_name = if job_class.nil?
                         # if job class cannot be safe_constantize-d, the job may be scheduled by a newer gitlab
                         # process.
                         # In this case, we use the store_name which may be set by the enqueuing process.
                         job_hash['store'] || 'main'
                       elsif unroutable_class?(job_class)
                         'main'
                       else
                         # When a worker's routing behaviour is updated by attribute or routing rule change,
                         # jobs could be rerouted using the wrong combination
                         # of either (1) old queue with new store or (2) new queue with old store.
                         #
                         # Update job hash's queue key to match this process's job_class configuration
                         # this ensures that the queue + store combination is valid.
                         if job_class.get_sidekiq_options['queue']
                           job_hash["queue"] = job_class.get_sidekiq_options['queue']
                         end

                         job_class.get_sidekiq_options['store']
                       end

          _, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(store_name)
          Sidekiq::Client.new(config: @config, pool: pool).push(job_hash)
        end

        def unroutable_class?(klass)
          klass.ancestors.exclude?(ApplicationWorker) &&
            # ActionMailer's ActiveJob pushes a job hash with
            # class: ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper into
            # the schedule set.
            klass != ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper
        end
      end

      def initialize(container)
        super

        @client = ScheduledEnqClient.new(container)
      end
    end
  end
end
