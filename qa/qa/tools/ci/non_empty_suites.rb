# frozen_string_literal: true

require 'open3'

module QA
  module Tools
    module Ci
      # Run count commands for scenarios and detect which ones have more than 0 examples to run
      #
      class NonEmptySuites
        include Helpers

        # @return [Array] scenarios that never run in package-and-test pipeline
        IGNORED_SCENARIOS = [
          "QA::EE::Scenario::Test::Geo",
          "QA::Scenario::Test::Instance::Airgapped"
        ].freeze

        def initialize(qa_tests)
          @qa_tests = qa_tests
        end

        # Run counts and return runnable scenario list
        #
        # @return [String]
        def fetch
          logger.info("Checking for runnable suites")
          scenarios.each_with_object([]) do |scenario, runnable_scenarios|
            logger.info(" fetching runnable specs for '#{scenario}'")
            next logger.info("  scenario is in ignore list, skipping") if IGNORED_SCENARIOS.include?(scenario)

            out, err, status = run_command(scenario)

            unless status.success?
              logger.error("  example count failed!\n#{err}")
              next
            end

            count = out.split("\n").last.to_i
            logger.info("  found #{count} examples to run")
            runnable_scenarios << scenario if count > 0
          end.join(",")
        end

        private

        attr_reader :qa_tests

        # Get all defined scenarios
        #
        # @return [Array<String>]
        def scenarios
          foss_scenarios = scenario_classes(QA::Scenario::Test)
          return foss_scenarios unless QA.const_defined?("QA::EE")

          foss_scenarios + scenario_classes(QA::EE::Scenario::Test)
        end

        # Fetch scenario classes recursively
        #
        # @param [Module] mod
        # @return [Array<String>]
        def scenario_classes(mod)
          mod.constants.map do |const|
            c = mod.const_get(const, false)
            next c.to_s if c.is_a?(Class)

            scenario_classes(c)
          end.flatten
        end

        # Run scenario count command
        #
        # @param [String] klass
        # @return [String]
        def run_command(klass)
          cmd = ["bundle exec bin/qa"]
          cmd << klass
          cmd << "--count-examples-only --address http://dummy1.test"
          cmd << "-- #{qa_tests}" unless qa_tests.blank?

          Open3.capture3(cmd.join(" "))
        end
      end
    end
  end
end
