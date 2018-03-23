module Gitlab
  module Git
    module Storage
      class CircuitBreaker
        include CircuitBreakerSettings

        attr_reader :storage,
                    :hostname

        delegate :last_failure, :failure_count, :no_failures?,
                 to: :failure_info

        def self.for_storage(storage)
          cached_circuitbreakers = RequestStore.fetch(:circuitbreaker_cache) do
            Hash.new do |hash, storage_name|
              hash[storage_name] = build(storage_name)
            end
          end

          cached_circuitbreakers[storage]
        end

        def self.build(storage, hostname = Gitlab::Environment.hostname)
          config = Gitlab.config.repositories.storages[storage]

          if !config.present?
            NullCircuitBreaker.new(storage, hostname, error: Misconfiguration.new("Storage '#{storage}' is not configured"))
          elsif !config.legacy_disk_path.present?
            NullCircuitBreaker.new(storage, hostname, error: Misconfiguration.new("Path for storage '#{storage}' is not configured"))
          else
            new(storage, hostname)
          end
        end

        def initialize(storage, hostname)
          @storage = storage
          @hostname = hostname
        end

        def perform
          return yield unless enabled?

          check_storage_accessible!

          yield
        end

        def circuit_broken?
          return false if no_failures?

          failure_count > failure_count_threshold
        end

        private

        # The circuitbreaker can be enabled for the entire fleet using a Feature
        # flag.
        #
        # Enabling it for a single host can be done setting the
        # `GIT_STORAGE_CIRCUIT_BREAKER` environment variable.
        def enabled?
          ENV['GIT_STORAGE_CIRCUIT_BREAKER'].present? || Feature.enabled?('git_storage_circuit_breaker')
        end

        def failure_info
          @failure_info ||= FailureInfo.load(cache_key)
        end

        def check_storage_accessible!
          if circuit_broken?
            raise Gitlab::Git::Storage::CircuitOpen.new("Circuit for #{storage} is broken", failure_reset_time)
          end
        end
      end
    end
  end
end
