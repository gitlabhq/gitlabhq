module Gitlab
  module Git
    module Storage
      class NullCircuitBreaker
        # These will have actual values
        attr_reader :storage,
                    :hostname

        # These will always have nil values
        attr_reader :storage_path,
                    :failure_wait_time,
                    :failure_reset_time,
                    :storage_timeout

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

        def failure_count_threshold
          1
        end

        def last_failure
          circuit_broken? ? Time.now : nil
        end

        def failure_count
          circuit_broken? ? 1 : 0
        end

        def failure_info
          Gitlab::Git::Storage::CircuitBreaker::FailureInfo.new(last_failure, failure_count)
        end
      end
    end
  end
end
