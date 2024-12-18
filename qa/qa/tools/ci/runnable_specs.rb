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
          QA::EE::Scenario::Test::Geo,
          QA::Scenario::Test::Instance::Airgapped,
          QA::Scenario::Test::Sanity::Selectors
        ].freeze

        def initialize(qa_tests)
          @qa_tests = qa_tests
        end

        # Return list of executable spec files for each scenario class
        #
        # @return [Hash<Class, Array<String>>]
        def fetch
          logger.info("Checking for runnable suites")
          (scenarios - IGNORED_SCENARIOS).each_with_object({}) do |scenario, runnable_scenarios|
            specs = fetch_specs(scenario)

            logger.info("  found #{specs.size} spec files to run")
            runnable_scenarios[scenario] = specs unless specs.empty?
          end
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
        # @return [Array<String>]
        def fetch_specs(klass)
          logger.info(" fetching runnable spec files for '#{klass}'")
          Tempfile.open("test-metadata.json") do |file|
            Process.fork do
              err = StringIO.new
              tags = klass.focus.presence || Specs::Runner::DEFAULT_SKIPPED_TAGS.map { |tag| "~#{tag}" }
              args = ["--dry-run", *tags.flat_map { |tag| ["-t", tag.to_s] }]
              qa_tests.blank? ? args.push(*Specs::Runner::DEFAULT_TEST_PATH_ARGS) : args.push(*qa_tests)

              # Clear variables that automatically add formatters in spec_helper
              %w[CI CI_SERVER COVERBAND_ENABLED].each { |var| ENV.delete(var) }
              RSpec.configure { |config| config.add_formatter(QA::Support::JsonFormatter, file.path) }

              status = RSpec::Core::Runner.run(args, err, StringIO.new)
              logger.error("  subprocess failed! Err output: #{err.string}") if status.nonzero?
              Kernel.exit(status)
            end
            _pid, status = Process.wait2
            raise "Failed to fetch executable spec files for #{klass}" unless status.success?

            JSON.load_file(file, symbolize_names: true)[:examples]
              .map { |example| example[:file_path].gsub("./", "") }
              .uniq
          end
        end
      end
    end
  end
end
