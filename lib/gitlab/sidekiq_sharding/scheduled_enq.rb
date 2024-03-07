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
          store_name = if job_class.nil? || job_class.ancestors.exclude?(ApplicationWorker)
                         'main'
                       else
                         job_class.get_sidekiq_options['store']
                       end

          _, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(store_name)
          Sidekiq::Client.new(config: @config, pool: pool).push(job_hash)
        end
      end

      def initialize(container)
        super

        @client = ScheduledEnqClient.new(container)
      end
    end
  end
end
