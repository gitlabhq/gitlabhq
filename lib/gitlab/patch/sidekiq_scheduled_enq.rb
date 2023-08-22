# frozen_string_literal: true

# Patch to address https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2286
# Using a dual-namespace poller eliminates the need for script based migration of
# schedule-related sets in Sidekiq.
module Gitlab
  module Patch
    module SidekiqScheduledEnq
      # The patched enqueue_jobs will poll non-namespaced scheduled sets before doing the same for
      # namespaced sets via super and vice-versa depending on how Sidekiq.redis was configured
      def enqueue_jobs(sorted_sets = Sidekiq::Scheduled::SETS)
        # checks the other namespace
        if Gitlab::Utils.to_boolean(ENV['SIDEKIQ_POLL_NON_NAMESPACED'])
          # Refer to https://github.com/sidekiq/sidekiq/blob/v6.5.7/lib/sidekiq/scheduled.rb#L25
          # this portion swaps out Sidekiq.redis for Gitlab::Redis::Queues
          Gitlab::Redis::Queues.with do |conn| # rubocop:disable Cop/RedisQueueUsage
            sorted_sets.each do |sorted_set|
              # adds namespace if `super` polls with a non-namespaced Sidekiq.redis
              if Gitlab::Utils.to_boolean(ENV['SIDEKIQ_ENQUEUE_NON_NAMESPACED'])
                sorted_set = "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:#{sorted_set}" # rubocop:disable Cop/RedisQueueUsage
              end

              while !@done && (job = zpopbyscore(conn, keys: [sorted_set], argv: [Time.now.to_f.to_s])) # rubocop:disable Gitlab/ModuleWithInstanceVariables, Lint/AssignmentInCondition
                Sidekiq::Client.push(Sidekiq.load_json(job)) # rubocop:disable Cop/SidekiqApiUsage
                Sidekiq.logger.debug { "enqueued #{sorted_set}: #{job}" }
              end
            end
          end
        end

        # calls original enqueue_jobs which may or may not be namespaced depending on SIDEKIQ_ENQUEUE_NON_NAMESPACED
        super
      end
    end
  end
end
