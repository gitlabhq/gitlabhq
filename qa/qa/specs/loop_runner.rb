# frozen_string_literal: true

module QA
  module Specs
    module LoopRunner
      module_function

      def run(args)
        start = Time.now
        loop_duration = 60 * QA::Runtime::Env.gitlab_qa_loop_runner_minutes

        while Time.now - start < loop_duration
          RSpec::Core::Runner.run(args.flatten, $stderr, $stdout).tap do |status|
            abort if status.nonzero?
          end
          RSpec.clear_examples
        end
      end
    end
  end
end
