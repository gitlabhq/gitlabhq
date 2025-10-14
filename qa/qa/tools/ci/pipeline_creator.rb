# frozen_string_literal: true

require "digest"

module QA
  module Tools
    module Ci
      # Pipeline creator class is responsible for creating child pipeline definitions
      #   of functional e2e tests dynamically. It relies on all child pipelines having the same structure where
      #   each pipeline will have a set of jobs running functional e2e tests. Dynamic scaling feature requires
      #   mapping between scenario classes and job names to exist. It also uses knapsack reports for test runtime
      #   data which is then used to calculate total runtime of particular functional e2e scenario class.
      #
      # Class support additional creation of other types of pipelines that will skip any runtime based dynamic logic.
      # This is useful to still retain functionality to create a noop pipeline when needed and might be otherwise hard
      #   to implement with pure gitlab CI rules.
      #
      class PipelineCreator
        # Supported functional e2e pipeline types that will be generated using dynamic scaling features
        # These are only values permitted in scenario class pipeline mappings
        #
        # @return [Array]
        FUNCTIONAL_E2E_PIPELINE_TYPES = %i[test_on_cng test_on_gdk test_on_omnibus].freeze

        # Additional pipeline types that will be created by simply copying pipeline definition without applying
        #   dynamic scaling logic
        # @return [Array]
        NON_FUNCTIONAL_PIPELINE_TYPES = %i[performance_on_cng].freeze

        # Runtime target in seconds for test run within single job
        #
        # @return [Float]
        TEST_RUNTIME_TARGET = (20 * 60).to_f

        # Additional coefficient to apply for parallel jobs calculation for fine tuning job count in specific pipeline:
        #  * jobs use parallel_tests to parallelize tests
        #  * tests are running slower than other environments (the case with test-on-gdk)
        #  * environment build is faster, so it's feasible to run less jobs that take slightly longer
        #  * pipeline does not run in merge requests, so less CI load with fewer slower jobs is acceptable
        # @return [Hash]
        RUNTIME_COEFFICIENT = {
          test_on_cng: 0.7, # cng supports parallel_tests, so less jobs are needed to retain target runtime
          test_on_gdk: 0.8, # gdk supports parallel_tests but is in general slower than other environments
          test_on_omnibus: 1.0
        }.freeze

        RULE_NEVER = "rules:\n  - when: never\n"

        # Generate noop pipeline file definitions for all supported pipelines
        #
        # @param pipeline_path [String]
        # @param logger [Logger]
        # @return [void]
        def self.create_noop(pipeline_path: "tmp", logger: Runtime::Logger.logger, reason: nil)
          new([], pipeline_path: pipeline_path, logger: logger).create_noop(reason: reason)
        end

        # @param tests [Array] specific tests to run
        # @param pipeline_path [String] path for generated pipeline files
        # @param env [Hash] environment configuration for generated pipelines
        # @param logger [Logger] logger instance
        # @return [void]
        def initialize(tests, pipeline_path: "tmp", env: {}, logger: Runtime::Logger.logger)
          @tests = tests
          @pipeline_path = pipeline_path
          @env = env
          @logger = logger
        end

        # Generate functional E2E test pipelines yaml files
        #
        # @param pipeline_types [Array] pipeline types to generate
        # @return [void]
        def create(pipeline_types = FUNCTIONAL_E2E_PIPELINE_TYPES)
          unless (pipeline_types - FUNCTIONAL_E2E_PIPELINE_TYPES).empty?
            raise(ArgumentError, "Unsupported pipeline type filter set!")
          end

          create_pipeline_definition_files(updated_pipeline_definitions(pipeline_types))
        end

        # Generate non functional E2E test pipeline yaml files
        #
        # @return [void]
        def create_non_functional
          base_variables = base_pipeline_variables.map { |k, v| "  #{k}: \"#{v}\"" }.join("\n")
          definitions = non_functional_test_pipeline_definitions.transform_values do |yml|
            "#{yml}\nvariables:\n#{base_variables}"
          end

          create_pipeline_definition_files(definitions)
        end

        # Create noop pipeline definitions for each supported pipeline type
        #
        # @return [void]
        def create_noop(reason: nil)
          noop_yml = noop_pipeline_yml(reason || "no-op run, nothing will be executed!")

          (FUNCTIONAL_E2E_PIPELINE_TYPES + NON_FUNCTIONAL_PIPELINE_TYPES).each do |type|
            # omnibus pipeline trigger defined an input and if it isn't present in no-op pipeline, it will fail
            # see trigger job definition 'e2e:test-on-omnibus-ee' in '.gitlab/ci/qa.gitlab-ci.yml'
            yml = if type == :test_on_omnibus
                    <<~YML
                      spec:
                        inputs:
                          pipeline-type:
                            type: string
                            default: external
                      ---
                      #{noop_yml}
                    YML
                  else
                    noop_yml
                  end

            File.write(generated_yml_file_name(type), yml)
          end
          logger.info("Created noop pipeline definitions for all E2E test pipelines")
        end

        private

        # @return [Array]
        attr_reader :tests

        # @return [String] path for generated pipeline definition files
        attr_reader :pipeline_path

        # @return [Hash<String, Object>]
        attr_reader :env

        # @return [Logger]
        attr_reader :logger

        # Project root path
        #
        # @return [String]
        def project_root
          @project_root ||= File.expand_path("../", Runtime::Path.qa_root)
        end

        # Content of noop pipeline definition file
        #
        # @return [String]
        def noop_pipeline
          @noop_pipeline ||= File.read(File.join(project_root, ".gitlab", "ci", "overrides", "skip.yml"))
        end

        # Path for ci configuration files
        #
        # @return [String]
        def ci_files_path
          @ci_files_path ||= if ENV["CI_PROJECT_NAMESPACE"] == "gitlab-cn"
                               File.join(project_root, "jh", ".gitlab", "ci")
                             else
                               File.join(project_root, ".gitlab", "ci")
                             end
        end

        # Functional test pipeline definitions
        #
        # @return [Hash<Symbol, String>]
        def functional_pipeline_definitions
          @functional_pipeline_definitions ||= FUNCTIONAL_E2E_PIPELINE_TYPES.index_with do |pipeline_type|
            File.read(File.join(ci_files_path, pipeline_type.to_s.tr("_", "-"), "main.gitlab-ci.yml"))
          end
        end

        # Non functional test pipeline definitions
        #
        # @return [Hash<Symbol, String>]
        def non_functional_test_pipeline_definitions
          @non_functional_test_pipeline_definitions ||= NON_FUNCTIONAL_PIPELINE_TYPES.index_with do |pipeline_type|
            File.read(File.join(ci_files_path, pipeline_type.to_s.tr("_", "-"), "main.gitlab-ci.yml"))
          end
        end

        # Example runtimes of all executed tests
        #
        # @return [Hash<String, Number>]
        def example_runtimes
          @example_runtimes ||= JSON.load_file(Support::KnapsackReport::RUNTIME_REPORT)
        end

        # File name for generated pipeline definition file
        #
        # @param pipeline_type [Symbol]
        # @return [String]
        def generated_yml_file_name(pipeline_type)
          File.join(pipeline_path, "#{pipeline_type.to_s.tr('_', '-')}-pipeline.yml")
        end

        # Specific examples to be executed
        #
        # @return [Hash<Class, Array<String>]
        def scenario_examples
          @scenario_examples ||= ScenarioExamples.fetch(tests)
        end

        # Base variables included in all pipeline types
        #
        # @return [Hash]
        def base_pipeline_variables
          @base_pipeline_variables ||= begin
            ruby_version = File.read(File.join(project_root, ".ruby-version")).strip

            {
              "RUBY_VERSION" => ENV["RUBY_VERSION"] || ruby_version,
              "GITLAB_SEMVER_VERSION" => File.read(File.join(project_root, "VERSION")),
              "FEATURE_FLAGS" => env["QA_FEATURE_FLAGS"]
            }.compact
          end
        end

        # Additional variables section for generated pipeline
        #
        # @return [String]
        def variables_section
          @pipeline_variables ||= "variables:\n".then do |variables|
            vars = {
              **base_pipeline_variables,
              # QA_SUITES is only used by test-on-omnibus due to pipeline being reusable in external projects
              "QA_SUITES" => executable_qa_suites,
              "QA_TESTS" => tests&.join(" ")
            }.filter_map { |k, v| "  #{k}: \"#{v}\"" unless v.blank? }.join("\n")

            "#{variables}#{vars}"
          end
        end

        # List of test suites that have executable tests
        #
        # @return [String]
        def executable_qa_suites
          @executable_qa_suites ||= scenario_runtimes
            # shorten suite klass name if it matches pattern
            # fallback to klass.to_s simplifies testing with anonymous classes
            .filter_map { |klass, runtime| klass.to_s.match(/^QA::.*(Test\S+)$/)&.[](1) || klass.to_s if runtime > 0 }
            .join(",")
        end

        # Total runtime value for each scenario that has pipeline mapping defined
        #
        # @return [Hash<Class, Number>]
        def scenario_runtimes
          @scenario_runtimes ||= scenario_examples
            .each_with_object(Hash.new { |hsh, key| hsh[key] = 0 }) do |(scenario, examples), runtimes|
              next unless scenario.pipeline_mapping

              executable_examples = examples.reject { |example| example[:status] == "pending" }
              # set runtime to 0 if particular scenario would skip all tests
              next runtimes[scenario] = 0 if executable_examples.empty?

              # Sum total runtime for all examples in scenario
              # Default to small value if runtimes report has no value for particular example
              # in order to not skip scenario entirely if report simply hasn't runtime data yet
              executable_examples.each { |example| runtimes[scenario] += example_runtimes[example[:id]] || 0.01 }
            end
        end

        # Create pipeline definition files
        #
        # @param definitions [Hash<Symbol, String>]
        # @return [void]
        def create_pipeline_definition_files(definitions)
          definitions.each do |type, yaml|
            file_name = generated_yml_file_name(type)
            File.write(file_name, yaml)
            logger.info("Pipeline definition file created: '#{file_name}'")
          end
        end

        # Pipeline job runtimes
        #
        # Hash with pipeline type as key and array of runtimes for each job running within that pipeline
        #
        # @return [Hash<Symbol, Array<Hash>]
        def pipeline_job_runtimes
          scenario_runtimes.each_with_object(Hash.new { |hsh, key| hsh[key] = [] }) do |(scenario, runtime), runtimes|
            scenario.pipeline_mapping.each do |pipeline_type, jobs|
              unless FUNCTIONAL_E2E_PIPELINE_TYPES.include?(pipeline_type)
                raise "Scenario class '#{scenario}' contains unsupported pipeline type '#{pipeline_type}'"
              end

              runtimes[pipeline_type].push(*jobs.map { |job| { name: job, runtime: runtime } })
            end
          end
        end

        # Updated pipeline yml files
        #
        # @param pipeline_types [Array<Symbol>]
        # @return [Hash<Symbol, String>]
        def updated_pipeline_definitions(pipeline_types)
          pipeline_job_runtimes.each_with_object({}) do |(pipeline_type, jobs), definitions|
            next unless pipeline_types.include?(pipeline_type)

            logger.info("Processing pipeline '#{pipeline_type}'")
            zero_runtime = jobs.all? { |job| job[:runtime] == 0 }
            if zero_runtime
              logger.info("  All jobs have zero runtime, creating 'no-op' pipeline")
              next definitions[pipeline_type] = noop_pipeline_yml("no-op run, pipeline has no executable tests")
            end

            pipeline = jobs.reduce(functional_pipeline_definitions[pipeline_type]) do |pipeline_yml, job|
              runtime_min = (job[:runtime] / 60).ceil
              logger.info("  Updating '#{job[:name]}' job based on total runtime of '#{runtime_min}' minutes")
              updated_job(job[:name], job[:runtime], pipeline_yml, pipeline_type)
            end
            definitions[pipeline_type] = "#{pipeline}\n#{variables_section}"
          end
        end

        # Update job definition in pipeline yml
        # Correctly set:
        #   * job parallel count
        #   * never rule if no tests are to be executed
        #   * specific tests variables depending on job parallelization
        #
        # @param job_name [String]
        # @param job_runtime [Number]
        # @param pipeline_yml [String]
        # @param pipeline_type [Symbol]
        # @return [String]
        def updated_job(job_name, job_runtime, pipeline_yml, pipeline_type)
          job_definition = job_definition(job_name, pipeline_yml)
          raise "Job definition not found for job '#{job_name}' in pipeline: #{pipeline_type}" unless job_definition
          return pipeline_yml.sub(job_definition, set_job_never_rule(job_definition)) if job_runtime == 0

          parallel_count = calculate_parallel_jobs_count(job_runtime, pipeline_type)
          pipeline_yml.sub(job_definition, update_job_parallel_count(job_definition, parallel_count))
        end

        # Get job definition from pipeline yaml
        #
        # @param job_name [String]
        # @param pipeline_yml [String]
        # @return [String, nil]
        def job_definition(job_name, pipeline_yml)
          pipeline_yml.match(/^#{job_name}:\n(?:\s{2}.*\n)+/)&.[](0)
        end

        # Set job rule to never in order to skip it's execution
        #
        # @param job_definition [String]
        # @param rule [String]
        # @return [String]
        def set_job_never_rule(job_definition)
          logger.info("   setting rule definition to 'never'")
          existing_rule = job_definition.match(/rules:\n(?:\s+-.*\n)+/)&.[](0)
          return "#{job_definition}  #{RULE_NEVER}" unless existing_rule

          job_definition.sub(existing_rule, RULE_NEVER)
        end

        # Update job parallel count
        #
        # @param job_definition [String]
        # @param parallel_count [Integer]
        # @return [String]
        def update_job_parallel_count(job_definition, parallel_count)
          pattern = /^(\s*parallel:) \d+$/

          logger.info("   setting parallel count to '#{parallel_count}'")
          return job_definition.sub(pattern, "\\1 #{parallel_count}") if job_definition.match?(pattern)

          "#{job_definition}  parallel: #{parallel_count}\n"
        end

        # Calculate needed parallel job count
        #
        # @param job_runtime [Number]
        # @param pipeline_type [Symbol]
        # @return [Integer]
        def calculate_parallel_jobs_count(job_runtime, pipeline_type)
          (job_runtime / TEST_RUNTIME_TARGET * RUNTIME_COEFFICIENT.fetch(pipeline_type, 1.0)).ceil
        end

        # No-op pipeline yml with skip reason message
        #
        # @param reason [String]
        # @return [String]
        def noop_pipeline_yml(reason)
          <<~YML
            variables:
              SKIP_MESSAGE: "#{reason}"

            #{noop_pipeline}
          YML
        end
      end
    end
  end
end
