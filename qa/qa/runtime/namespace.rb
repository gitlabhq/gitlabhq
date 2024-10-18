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

        # Predefined top level group name
        #
        # @return [String]
        def sandbox_name
          @sandbox_name ||= Runtime::Env.sandbox_name ||
            if !QA::Runtime::Env.running_on_dot_com? && QA::Runtime::Env.run_in_parallel?
              "gitlab-qa-sandbox-group-#{SecureRandom.hex(4)}-#{Time.now.wday + 1}"
            else
              "gitlab-qa-sandbox-group-#{Time.now.wday + 1}"
            end
        end
      end
    end
  end
end
