# frozen_string_literal: true

require "etc"

module QA
  module Specs
    class ParallelRunner
      class << self
        def run(rspec_args)
          cli_args = build_execution_args(rspec_args)

          Runtime::Logger.debug("Using parallel runner to trigger tests with arguments: '#{cli_args}'")

          set_environment!
          perform_global_setup!

          ParallelTests::CLI.new.run(cli_args)
        end

        private

        delegate :parallel_processes, to: Runtime::Env

        def build_execution_args(rspec_args)
          specs = rspec_args.select { |arg| arg.include?("qa/specs/features") }
          options = (rspec_args - specs).reject { |arg| arg == "--" }
          # if amount of specs is less than parallel processes, use the amount of specs as count
          # to avoid starting empty runs with no tests
          used_processes = !specs.empty? && specs.size < parallel_processes ? specs.size : parallel_processes

          cli_args = [
            "--type", "rspec",
            "-n", used_processes.to_s,
            "--serialize-stdout",
            '--first-is-1',
            "--combine-stderr"
          ]
          cli_args.push("--", *options) unless options.empty?
          cli_args.push("--", *specs) unless specs.empty? # specific specs need to be seperated by additional "--"

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
      end
    end
  end
end
