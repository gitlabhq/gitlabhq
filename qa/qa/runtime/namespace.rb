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
          Env.namespace_name || "qa-test-#{time.strftime('%Y-%m-%d-%H-%M-%S')}-#{SecureRandom.hex(8)}"
        end

        # Top level group name
        #
        # @return [String]
        def sandbox_name
          return "gitlab-qa-sandbox-group-#{Time.now.wday + 1}" if live_env?

          "qa-sandbox-#{SecureRandom.hex(6)}"
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
      end
    end
  end
end
