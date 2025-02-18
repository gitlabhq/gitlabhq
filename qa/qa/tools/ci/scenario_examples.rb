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
          new(qa_tests).fetch
        end

        def initialize(qa_tests = nil)
          @qa_tests = qa_tests
        end

        # Return list of executable examples for each scenario class
        #
        # @return [Hash<Class, Array<Hash>>]
        def fetch
          logger.info("Fetching executable examples for all scenario classes")
          (all_scenario_classes - ignored_scenarios).each_with_object({}) do |scenario, scenarios|
            examples = fetch_examples(scenario)
            skipped_examples = examples.select { |example| example[:status] == "pending" }

            logger.info(" detected examples, total: #{examples.size}, skipped: #{skipped_examples.size}")
            scenarios[scenario] = examples
          end
        end

        private

        attr_reader :qa_tests

        # Ignored scenarios classes
        #
        # @return [Array<Class>]
        def ignored_scenarios
          return IGNORED_SCENARIOS.map(&:constantize) if QA.const_defined?("QA::EE")

          IGNORED_SCENARIOS.reject { |scenario| scenario.include?("EE") }.map(&:constantize)
        end

        # Get all defined scenarios
        #
        # @return [Array<Class>]
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
        # @return [Array<Hash>]
        def fetch_examples(klass)
          logger.info("Fetching examples for scenario '#{klass}'")

          spec_pattern = klass.spec_pattern
          scenario_tests = scenario_class_tests(spec_pattern)
          return [] if spec_pattern && scenario_tests.empty? # no executable specs for this scenario class

          Support::ExampleData.fetch(klass.focus, scenario_tests, logger: logger).map do |example|
            example.slice(:id, :status)
          end
        end

        # Specs for particular scenario class if it defines specific spec pattern
        #
        # @param pattern [String, nil]
        # @return [Array]
        def scenario_class_tests(pattern)
          return qa_tests if pattern.nil?

          scenario_tests = Dir.glob(pattern)
          return scenario_tests if qa_tests.nil? || qa_tests.empty?

          qa_tests.flat_map do |path|
            next path if File.file?(path) && File.fnmatch(pattern, path)
            next specs_in_path(path, scenario_tests) if File.directory?(path)

            []
          end
        end

        # List of specs within a path
        #
        # @param path [String]
        # @param scenario_specs [Array]
        # @return [Array]
        def specs_in_path(path, scenario_specs)
          scenario_specs.select { |spec| spec.match?(%r{#{Specs::Runner::ABSOLUTE_PATH_PREFIX_PATTERN}#{path}}) }
        end
      end
    end
  end
end
