module Gitlab
  module Git
    module Storage
      class Inaccessible < StandardError
        attr_reader :retry_after

        def initialize(message = nil, retry_after = nil)
          super(message)
          @retry_after = retry_after
        end
      end

      CircuitOpen = Class.new(Inaccessible)
      Misconfiguration = Class.new(Inaccessible)
      Failing = Class.new(Inaccessible)

      REDIS_KEY_PREFIX = 'storage_accessible:'.freeze
      REDIS_KNOWN_KEYS = "#{REDIS_KEY_PREFIX}known_keys_set".freeze

      def self.redis
        Gitlab::Redis::SharedState
      end
    end
  end
end
