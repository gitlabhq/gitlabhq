# frozen_string_literal: true

module QA
  module Specs
    class KnapsackRunner
      def self.run(args, parallel: false)
        QA::Support::KnapsackReport.configure!

        allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

        Knapsack.logger.info '==== Knapsack specs to execute ====='
        Knapsack.logger.info 'Report specs:'
        Knapsack.logger.info allocator.report_node_tests
        Knapsack.logger.info 'Leftover specs:'
        Knapsack.logger.info allocator.leftover_node_tests

        if parallel
          rspec_args = args.reject { |arg| arg == "--" || arg.start_with?("qa/specs/features") }
          run_args = [*rspec_args, '--', *allocator.node_tests]
          return ParallelRunner.run(run_args)
        end

        status = RSpec::Core::Runner.run([*args, '--', *allocator.node_tests])
        yield status if block_given?
        status
      end
    end
  end
end
