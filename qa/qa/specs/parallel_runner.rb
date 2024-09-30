# frozen_string_literal: true

require "parallel_tests"
require "etc"

module QA
  module Specs
    class ParallelRunner
      class << self
        def run(rspec_args)
          used_processes = Runtime::Env.parallel_processes

          args = [
            "--type", "rspec",
            "-n", used_processes.to_s,
            "--serialize-stdout",
            '--first-is-1',
            "--combine-stderr"
          ]

          unless rspec_args.include?('--')
            index = rspec_args.index { |opt| opt.include?("qa/specs/features") }

            rspec_args.insert(index, '--') if index
          end

          args.push("--", *rspec_args) unless rspec_args.empty?

          set_environment!
          perform_global_setup!

          ParallelTests::CLI.new.run(args)
        end

        private

        def perform_global_setup!
          Runtime::Browser.configure!
          Runtime::Release.perform_before_hooks
        end

        def set_environment!
          ENV.store("NO_KNAPSACK", "true")
          ENV.store("QA_PARALLEL_RUN", "true")

          return if ENV["QA_GITLAB_URL"].present?

          Support::GitlabAddress.define_gitlab_address_attribute!
          ENV.store("QA_GITLAB_URL", Support::GitlabAddress.address_with_port(with_default_port: false))
        end
      end
    end
  end
end
