# frozen_string_literal: true

require 'open3'

module QA
  module Specs
    module ParallelRunner
      module_function

      def run(args)
        unless args.include?('--')
          index = args.index { |opt| opt.include?('features') }

          args.insert(index, '--') if index
        end

        env = {}
        Runtime::Env::ENV_VARIABLES.each_key do |key|
          env[key] = ENV[key] if ENV[key]
        end
        env['QA_RUNTIME_SCENARIO_ATTRIBUTES'] = Runtime::Scenario.attributes.to_json
        env['GITLAB_QA_ACCESS_TOKEN'] = Runtime::API::Client.new(:gitlab).personal_access_token unless env['GITLAB_QA_ACCESS_TOKEN']

        cmd = "bundle exec parallel_test -t rspec --combine-stderr --serialize-stdout -- #{args.flatten.join(' ')}"
        ::Open3.popen2e(env, cmd) do |_, out, wait|
          out.each { |line| puts line }

          exit wait.value.exitstatus
        end
      end
    end
  end
end
