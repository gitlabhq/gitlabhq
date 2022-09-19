# frozen_string_literal: true

require 'open3'

module QA
  module Tools
    module Ci
      # Run count commands for scenarios and detect which ones have more than 0 examples to run
      #
      class NonEmptySuites
        include Helpers

        # rubocop:disable Layout/LineLength
        SCENARIOS = [
          { klass: "Test::Instance::All" },
          { klass: "Test::Instance::Smoke" },
          { klass: "Test::Instance::Reliable" },
          { klass: "Test::Instance::ReviewBlocking" },
          { klass: "Test::Instance::ReviewNonBlocking" },
          { klass: "Test::Instance::CloudActivation" },
          { klass: "Test::Instance::Integrations" },
          { klass: "Test::Instance::Jira" },
          { klass: "Test::Instance::LargeSetup" },
          { klass: "Test::Instance::Metrics" },
          { klass: "Test::Instance::ObjectStorage" },
          { klass: "Test::Instance::Packages" },
          { klass: "Test::Instance::RepositoryStorage" },
          { klass: "Test::Integration::ServicePingDisabled" },
          { klass: "Test::Integration::LDAPNoTLS" },
          { klass: "Test::Integration::LDAPTLS" },
          { klass: "Test::Integration::LDAPNoServer" },
          { klass: "Test::Integration::InstanceSAML" },
          { klass: "Test::Integration::RegistryWithCDN" },
          { klass: "Test::Integration::RegistryTLS" },
          { klass: "Test::Integration::Registry" },
          { klass: "Test::Integration::SMTP" },
          { klass: "QA::EE::Scenario::Test::Integration::Elasticsearch" },
          { klass: "QA::EE::Scenario::Test::Integration::GroupSAML" },
          {
            klass: "QA::EE::Scenario::Test::Geo",
            args: "--primary-address http://dummy1.test --primary-name gitlab-primary --secondary-address http://dummy2.test --secondary-name gitlab-secondary --without-setup"
          },
          {
            klass: "Test::Integration::Mattermost",
            args: "--mattermost-address http://mattermost.test"
          }
        ].freeze
        # rubocop:enable Layout/LineLength

        def initialize(qa_tests)
          @qa_tests = qa_tests
        end

        # Run counts and return runnable scenario list
        #
        # @return [String]
        def fetch
          logger.info("Checking for runnable suites")
          scenarios = SCENARIOS.each_with_object([]) do |scenario, runnable_scenarios|
            logger.info(" fetching runnable specs for '#{scenario[:klass]}'")

            out, err, status = run_command(**scenario)

            unless status.success?
              logger.error(" example count failed!\n#{err}")
              next
            end

            count = out.split("\n").last.to_i
            logger.info("  found #{count} examples to run")
            runnable_scenarios << scenario[:klass] if count > 0
          end

          scenarios.join(",")
        end

        private

        attr_reader :qa_tests

        # Run scenario count command
        #
        # @param [String] klass
        # @param [String] args
        # @return [String]
        def run_command(klass:, args: nil)
          cmd = ["bundle exec bin/qa"]
          cmd << klass
          cmd << "--count-examples-only --address http://dummy1.test"
          cmd << args if args
          cmd << "-- #{qa_tests}" unless qa_tests.blank?

          Open3.capture3(cmd.join(" "))
        end
      end
    end
  end
end
