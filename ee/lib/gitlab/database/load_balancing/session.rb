module Gitlab
  module Database
    module LoadBalancing
      # Tracking of load balancing state per user session.
      #
      # A session starts at the beginning of a request and ends once the request
      # has been completed. Sessions can be used to keep track of what hosts
      # should be used for queries.
      class Session
        CACHE_KEY = :gitlab_load_balancer_session

        attr_accessor :last_write_location

        def self.current
          RequestStore[CACHE_KEY] ||= new
        end

        def self.clear_session
          RequestStore.delete(CACHE_KEY)
        end

        def initialize
          @transaction_nesting = 0

          reset!
        end

        def reset!
          @last_write_location = nil
          @use_primary = false
          @performed_write = false
        end

        def use_primary?
          @use_primary
        end

        def enter_transaction
          @transaction_nesting += 1
        end

        def leave_transaction
          @transaction_nesting -= 1
        end

        def in_transaction?
          @transaction_nesting.positive?
        end

        def use_primary!
          @use_primary = true
        end

        def write!
          @performed_write = true
          use_primary!
        end

        def performed_write?
          @performed_write
        end
      end
    end
  end
end
