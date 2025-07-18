# frozen_string_literal: true

module QA
  module Runtime
    # Global helper methods for unique group name generation
    #
    # Avoid using directly, instead use through fabricated instances of Sandbox and Group resources
    module Namespace
      class << self
        def time
          @time ||= Time.now
        end

        # Random group name with specific pattern
        #
        # @return [String]
        def group_name
          Env.namespace_name || "e2e-test-#{time.strftime('%Y-%m-%d-%H-%M-%S')}-#{SecureRandom.hex(8)}"
        end

        # Top level group name
        #
        # @return [String]
        def sandbox_name
          return "gitlab-e2e-sandbox-group-#{sandbox_number}" if live_env?

          "e2e-sandbox-#{SecureRandom.hex(6)}"
        end

        private

        # Test is running on live environment with limitations for top level group creation
        #
        # @return [Boolean]
        def live_env?
          return @live_env unless @live_env.nil?

          # Memoize the result of this check so every call doesn't parse gitlab address and check hostname
          # There is no case to change gitlab address in the middle of test process so it should be safe to do
          @live_env = Runtime::Env.running_on_live_env?
        end

        # Determines the sandbox group number for live environments
        #
        # Live environments (like .com) have exactly 8 pre-created sandbox groups
        # (gitlab-e2e-sandbox-group-1 through gitlab-e2e-sandbox-group-8). This method
        # maps CI_NODE_INDEX values to the available 1-8 range using modulo arithmetic
        # to handle parallel jobs with more than 8 nodes. When CI_NODE_INDEX is not
        # set, returns a memoized random number between 1-8.
        #
        # @return [Integer] A number between 1 and 8 inclusive, corresponding to available sandbox groups
        # @example
        #   ENV['CI_NODE_INDEX'] = '1'  # returns 1 (gitlab-e2e-sandbox-group-1)
        #   ENV['CI_NODE_INDEX'] = '9'  # returns 1 (wraps to gitlab-e2e-sandbox-group-1)
        #   ENV['CI_NODE_INDEX'] = nil  # returns random 1-8 (memoized)
        def sandbox_number
          ENV['CI_NODE_INDEX'] ? ((ENV['CI_NODE_INDEX'].to_i - 1) % 8) + 1 : @random_sandbox_id ||= rand(1..8)
        end
      end
    end
  end
end
