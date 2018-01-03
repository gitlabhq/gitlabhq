module Gitlab
  module Git
    module Storage
      class NullCircuitBreaker
        include CircuitBreakerSettings

        # These will have actual values
        attr_reader :storage,
                    :hostname

        # These will always have nil values
        attr_reader :storage_path

        delegate :last_failure, :failure_count, :no_failures?,
                 to: :failure_info

        def initialize(storage, hostname, error: nil)
          @storage = storage
          @hostname = hostname
          @error = error
        end

        def perform
          @error ? raise(@error) : yield
        end

        def circuit_broken?
          !!@error
        end

        def backing_off?
          false
        end

        def failure_info
          @failure_info ||=
            if circuit_broken?
              Gitlab::Git::Storage::FailureInfo.new(Time.now,
                                                    Time.now,
                                                    failure_count_threshold)
            else
              Gitlab::Git::Storage::FailureInfo.new(nil,
                                                    nil,
                                                    0)
            end
        end
      end
    end
  end
end
