# frozen_string_literal: true

module QA
  module Tools
    module Ci
      # Execute rspec dry run to get list of executable specs for each scenario class
      #
      class ScenarioExamples
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

        # Return list of executable examples for each scenario class
        #
        # @param qa_tests [Array<String>]
        # @return [Hash<Class, Array<Hash>>]
        def fetch(qa_tests = nil)
          logger.info("Fetching executable examples for all scenario classes")
          (all_scenario_classes - ignored_scenarios).each_with_object({}) do |scenario, scenarios|
            examples = fetch_examples(scenario, qa_tests)
            skipped_examples = examples.select { |example| example[:status] == "pending" }

            logger.info(" detected examples, total: #{examples.size}, skipped: #{skipped_examples.size}")
            scenarios[scenario] = examples
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
        def all_scenario_classes
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

        # Fetch list of executable examples for scenario class
        #
        # @param klass [Class]
        # @param qa_tests [Array<String>]
        # @return [Array<Hash>]
        def fetch_examples(klass, tests)
          logger.info("Fetching examples for scenario '#{klass}'")
          Support::ExampleData.fetch(klass.focus, tests, logger: logger).map do |example|
            example.slice(:id, :status)
          end
        end
      end
    end
  end
end
