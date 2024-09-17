# frozen_string_literal: true

module Gitlab
  module SidekiqSharding
    module Validator
      UnroutedSidekiqApiError = Class.new(StandardError)

      module Client
        extend ActiveSupport::Concern

        class_methods do
          # Sets inside_sidekiq_via_scope state to true to avoid error when validation is called
          def via(pool)
            in_via_state = Thread.current[:inside_sidekiq_via_scope]
            Thread.current[:inside_sidekiq_via_scope] = true

            super(pool)
          ensure
            Thread.current[:inside_sidekiq_via_scope] = in_via_state
          end
        end
      end

      class << self
        # Used to allow Sidekiq API or Sidekiq.redis for spec set-ups and components
        # that does not require sharding such as CronJobs (performed using Sidekiq.redis).
        def allow_unrouted_sidekiq_calls
          currently_allowed = Thread.current[:allow_unrouted_sidekiq_calls]
          Thread.current[:allow_unrouted_sidekiq_calls] = true

          yield
        ensure
          Thread.current[:allow_unrouted_sidekiq_calls] = currently_allowed
        end

        # This allows us to perform validation within the scope of GitLab application logic
        # without needing to modify/patch Sidekiq internals such as job fetching, cron-polling, and housekeeping.
        def enabled
          validate_sidekiq_shard_awareness = Thread.current[:validate_sidekiq_shard_awareness]
          Thread.current[:validate_sidekiq_shard_awareness] = true

          yield
        ensure
          Thread.current[:validate_sidekiq_shard_awareness] = validate_sidekiq_shard_awareness
        end
      end

      Sidekiq::RedisClientAdapter::CompatMethods::USED_COMMANDS.each do |name|
        define_method(name) do |*args, **kwargs|
          validate! if Thread.current[:validate_sidekiq_shard_awareness]

          super(*args, **kwargs)
        end
      end

      # This is used to patch the Sidekiq::RedisClientAdapter to validate all Redis commands are routed
      # rubocop:disable Style/MissingRespondToMissing -- already defined in the module we are patching
      def method_missing(*args, &block)
        validate! if Thread.current[:validate_sidekiq_shard_awareness]

        super(*args, &block)
      end
      ruby2_keywords :method_missing if respond_to?(:ruby2_keywords, true)
      # rubocop:enable Style/MissingRespondToMissing

      private

      def validate!
        return if Thread.current[:allow_unrouted_sidekiq_calls]
        return if Thread.current[:inside_sidekiq_via_scope]

        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          UnroutedSidekiqApiError.new("Sidekiq Redis called outside a .via block")
        )
      end
    end
  end
end
