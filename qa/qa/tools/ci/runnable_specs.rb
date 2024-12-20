# frozen_string_literal: true

module QA
  module Tools
    module Ci
      # Execute rspec dry run to get list of executable specs for each scenario class
      #
      class RunnableSpecs
        include Helpers

        # @return [Array] scenarios that never run in test-on-omnibus pipeline
        IGNORED_SCENARIOS = [
          "QA::EE::Scenario::Test::Geo",
          "QA::Scenario::Test::Instance::Airgapped",
          "QA::Scenario::Test::Sanity::Selectors"
        ].freeze

        def self.fetch(qa_tests = nil)
          new.fetch(qa_tests)
        end

        # Return list of executable spec files for each scenario class
        #
        # @param qa_tests [Array<String>]
        # @return [Hash<Class, Array<String>>]
        def fetch(qa_tests = nil)
          logger.info("Checking for runnable suites")
          (scenarios - ignored_scenarios).each_with_object({}) do |scenario, runnable_scenarios|
            specs = fetch_specs(scenario, qa_tests)

            logger.info(" found #{specs.size} spec files to run")
            runnable_scenarios[scenario] = specs unless specs.empty?
          end
        end

        private

        # Ignored scenarios classes
        #
        # @return [Array<Class>]
        def ignored_scenarios
          return IGNORED_SCENARIOS.map(&:constantize) if QA.const_defined?("QA::EE")

          IGNORED_SCENARIOS.reject { |scenario| scenario.include?("EE") }.map(&:constantize)
        end

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
        # @return [Array<Object>]
        def scenario_classes(mod)
          mod.constants.flat_map do |const|
            c = mod.const_get(const, false)
            next c if c.is_a?(Class)

            scenario_classes(c)
          end
        end

        # Fetch list of executable spec files for scenario class
        #
        # @param klass [Class]
        # @param qa_tests [Array<String>]
        # @return [Array<String>]
        def fetch_specs(klass, tests)
          logger.info("Fetching runnable spec files for '#{klass}'")
          Support::ExampleData.fetch(klass.focus, tests, logger: logger)
            .map { |example| example[:file_path].gsub("./", "") }
            .uniq
        end
      end
    end
  end
end
