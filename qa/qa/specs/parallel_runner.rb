# frozen_string_literal: true

require "etc"

module QA
  module Specs
    class ParallelRunner
      RUNTIME_LOG_FILE = "tmp/parallel_runtime_rspec.log"

      def self.run(rspec_args, paths, example_data)
        new(rspec_args, paths, example_data).run
      end

      def initialize(rspec_args, paths, example_data)
        @rspec_args = rspec_args
        @example_data = example_data
        @paths = paths
      end

      # Execute tests using parallel runner
      #
      # @return [void]
      def run
        Runtime::Logger.debug("Using parallel runner to trigger tests with arguments: '#{execution_args}'")

        set_environment!
        perform_global_setup!
        create_runtime_log!

        ParallelTests::CLI.new.run(execution_args)
      end

      private

      # @return [Array<String>]
      attr_reader :rspec_args

      # @return [Array<String>]
      attr_reader :paths

      # @return [Hash<String, String>]
      attr_reader :example_data

      # Specific spec paths are default paths containing all specs
      #
      # @return [Boolean]
      def default_paths?
        paths == Runner::DEFAULT_TEST_PATH_ARGS
      end

      # Executable specs based on example data
      #
      # @return [Array<String>]
      def executable_specs
        @executable_specs ||= example_data.each_with_object([]) do |(id, status), paths|
          paths << id.match(%r{\./(\S+)\[\S+\]})[1] if status == "passed"
        end.uniq
      end

      # Parallel processes
      #
      # If amount of explicitly passed spec files is smaller than configured processes, set it to spec files amount
      #
      # @return [Integer]
      def parallel_processes
        spec_files = path_options.select { |arg| arg.match?(/^.*_spec.rb$/) }
        processes = Runtime::Env.parallel_processes
        return spec_files.size if !spec_files.empty? && spec_files.size < processes

        processes
      end

      # Rspec path options
      #
      # When default path is used, parallel runner will try to split tests based on the amount of spec files found
      # within the path even though rspec tags would end up skipping most of these tests
      # To avoid spawning processes that skip all tests, set spec paths based on example data which takes in to
      # account which tags have been used
      #
      # @return [Array]
      def path_options
        @path_options ||= default_paths? ? executable_specs : paths
      end

      # Execution arguments for parallel runner
      #
      # @return [Array]
      def execution_args
        return @execution_args if @execution_args

        @execution_args = [
          "--type", "rspec",
          "-n", parallel_processes.to_s,
          "--runtime-log", RUNTIME_LOG_FILE,
          "--serialize-stdout",
          '--first-is-1',
          "--combine-stderr"
        ]
        @execution_args.push("--", *rspec_args) unless rspec_args.empty?
        # specific spec paths need to be separated by additional "--"
        @execution_args.push("--", *path_options) unless path_options.empty?

        @execution_args
      end

      # Perform global test setup once before starting parallel processes
      #
      # @return [void]
      def perform_global_setup!
        Runtime::Browser.configure!
        Runtime::Release.perform_before_hooks
      end

      # Set necessary environment variables for parallel processes
      #
      # @return [void]
      def set_environment!
        ENV.store("NO_KNAPSACK", "true")

        return if ENV["QA_GITLAB_URL"].present?

        Support::GitlabAddress.define_gitlab_address_attribute!
        ENV.store("QA_GITLAB_URL", Support::GitlabAddress.address_with_port(with_default_port: false))
      end

      # Create test runtime log
      #
      # @return [void]
      def create_runtime_log!
        Runtime::Logger.debug("Creating runtime log file for parallel runner")
        knapsack_report = Support::KnapsackReport.knapsack_report(example_data)
        File.write(RUNTIME_LOG_FILE, knapsack_report.map { |spec, runtime| "#{spec}:#{runtime}" }.join("\n"))
      end
    end
  end
end
