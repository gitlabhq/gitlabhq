# frozen_string_literal: true

module QA
  module Specs
    class KnapsackRunner
      class << self
        def run(args, rspec_paths, example_data, parallel: false)
          test_pattern = knapsack_pattern(rspec_paths)

          knapsack_reporter = Support::KnapsackReport.new(test_pattern: test_pattern)
          knapsack_reporter.configure!
          knapsack_reporter.create_local_report!(example_data)

          allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

          Knapsack.logger.info '==== Knapsack specs to execute ====='
          Knapsack.logger.info 'Report specs:'
          Knapsack.logger.info allocator.report_node_tests
          Knapsack.logger.info 'Leftover specs:'
          Knapsack.logger.info allocator.leftover_node_tests

          return ParallelRunner.run(args, allocator.node_tests, example_data) if parallel

          status = RSpec::Core::Runner.run([*args, '--', *allocator.node_tests])
          yield status if block_given?
          status
        end

        private

        # Create knapsack pattern from spec paths
        #
        # @param spec_paths [Array<String>]
        # @return [Array<String>]
        def knapsack_pattern(spec_paths)
          paths = spec_paths.map do |path|
            relative_path = path.gsub("#{Runtime::Path.qa_root}/", '')
            File.directory?(relative_path) ? "#{relative_path}/**/*_spec.rb" : relative_path
          end

          "{#{paths.join(',')}}"
        end
      end
    end
  end
end
