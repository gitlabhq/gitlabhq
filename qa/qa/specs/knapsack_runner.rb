# frozen_string_literal: true

module QA
  module Specs
    class KnapsackRunner
      def self.run(args)
        QA::Support::KnapsackReport.configure!

        allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

        Knapsack.logger.info '==== Knapsack specs to execute ====='
        Knapsack.logger.info 'Report specs:'
        Knapsack.logger.info allocator.report_node_tests
        Knapsack.logger.info 'Leftover specs:'
        Knapsack.logger.info allocator.leftover_node_tests

        status = RSpec::Core::Runner.run([*args, '--', *allocator.node_tests])
        yield status if block_given?
        status
      end
    end
  end
end
