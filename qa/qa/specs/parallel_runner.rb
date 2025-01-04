# frozen_string_literal: true

require "etc"

module QA
  module Specs
    class ParallelRunner
      RUNTIME_LOG_FILE = "tmp/parallel_runtime_rspec.log"

      class << self
        def run(rspec_args, knapsack_report)
          cli_args = build_execution_args(rspec_args)

          Runtime::Logger.debug("Using parallel runner to trigger tests with arguments: '#{cli_args}'")

          set_environment!
          perform_global_setup!
          create_runtime_log!(knapsack_report)

          ParallelTests::CLI.new.run(cli_args)
        end

        private

        delegate :parallel_processes, to: Runtime::Env

        def build_execution_args(rspec_args)
          paths = rspec_args.select { |arg| arg.include?("qa/specs/features") }
          spec_files = paths.select { |arg| arg.match?(/^.*_spec.rb$/) }
          options = (rspec_args - paths).reject { |arg| arg == "--" }
          # if amount of explicitly passed specs is less than parallel processes, use the amount of specs as count
          # to avoid starting empty runs with no tests
          used_processes = if !spec_files.empty? && spec_files.size < parallel_processes
                             spec_files.size
                           else
                             parallel_processes
                           end

          cli_args = [
            "--type", "rspec",
            "-n", used_processes.to_s,
            "--runtime-log", RUNTIME_LOG_FILE,
            "--serialize-stdout",
            '--first-is-1',
            "--combine-stderr"
          ]
          cli_args.push("--", *options) unless options.empty?
          cli_args.push("--", *paths) unless paths.empty? # specific spec paths need to be separated by additional "--"

          cli_args
        end

        def perform_global_setup!
          Runtime::Browser.configure!
          Runtime::Release.perform_before_hooks
        end

        def set_environment!
          ENV.store("NO_KNAPSACK", "true")

          return if ENV["QA_GITLAB_URL"].present?

          Support::GitlabAddress.define_gitlab_address_attribute!
          ENV.store("QA_GITLAB_URL", Support::GitlabAddress.address_with_port(with_default_port: false))
        end

        # Create test runtime log
        #
        # @param knapsack_report [Hash<String, Number>]
        # @return [void]
        def create_runtime_log!(knapsack_report)
          Runtime::Logger.debug("Creating runtime log file for parallel runner")
          File.write(RUNTIME_LOG_FILE, knapsack_report.map { |spec, runtime| "#{spec}:#{runtime}" }.join("\n"))
        end
      end
    end
  end
end
