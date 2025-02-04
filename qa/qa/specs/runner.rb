# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'tempfile'

module QA
  module Specs
    class Runner < Scenario::Template
      attr_accessor :tty, :tags, :spec_pattern, :options

      RegexMismatchError = Class.new(StandardError)

      DEFAULT_TEST_PATH = "qa/specs/features"
      DEFAULT_TEST_PATH_ARGS = [DEFAULT_TEST_PATH].freeze
      DEFAULT_STD_ARGS = [$stderr, $stdout].freeze
      DEFAULT_SKIPPED_TAGS = %w[~orchestrated].freeze

      ABSOLUTE_PATH_PREFIX_PATTERN = %r{^(\./|#{Runtime::Path.qa_root})?}

      def initialize
        @tty = false
        @tags = []
        @options = []
      end

      def perform
        args = build_initial_args
        # use options from default .rspec file for metadata only runs
        configure_default_formatters!(args) unless metadata_run?

        run_rspec(args.flatten)
      end

      private

      delegate :rspec_retried?, :parallel_run?, to: Runtime::Env

      def rspec_tags
        return @rspec_tags if @rspec_tags

        tags_for_rspec = []

        if Runtime::Scenario.attributes[:test_metadata_only] || Runtime::Env.rspec_retried?
          return @rspec_tags = tags_for_rspec
        end

        if tags.any?
          tags.each { |tag| tags_for_rspec.push(tag.to_s) }
        else
          tags_for_rspec.push(*DEFAULT_SKIPPED_TAGS) unless (%w[-t --tag] & options).any?
        end

        tags_for_rspec.push("~geo") unless QA::Runtime::Env.geo_environment?
        tags_for_rspec.push("~skip_signup_disabled") if QA::Runtime::Env.signup_disabled?
        tags_for_rspec.push("~skip_live_env") if QA::Specs::Helpers::ContextSelector.dot_com?

        QA::Runtime::Env.supported_features.each_key do |key|
          tags_for_rspec.push("~requires_#{key}") unless QA::Runtime::Env.can_test? key
        end

        @rspec_tags = tags_for_rspec
      end

      def custom_spec_paths
        @spec_paths ||= options.select { |opt| opt.include?(DEFAULT_TEST_PATH) }
      end

      def scenario_specs
        return [] unless spec_pattern

        @scenario_specs ||= Dir.glob(spec_pattern)
      end

      def rspec_paths
        return @rspec_paths if @rspec_paths

        paths = custom_spec_paths.presence || DEFAULT_TEST_PATH_ARGS
        return @rspec_paths = paths unless spec_pattern

        @rspec_paths = paths.flat_map do |path|
          next path if File.file?(path) && File.fnmatch(spec_pattern, path)
          next specs_in_path(path) if File.directory?(path)

          []
        end
      end

      def specs_in_path(path)
        scenario_specs.select { |spec| spec.match?(%r{#{ABSOLUTE_PATH_PREFIX_PATTERN}#{path}}) }
      end

      def build_initial_args
        [].tap do |args|
          args.push('--tty') if tty
          args.push(rspec_tags.flat_map { |tag| ["--tag", tag] })
          args.push(options - custom_spec_paths)
        end
      end

      def run_rspec(args)
        full_arg_list = [*args, "--", *rspec_paths]

        if rspec_paths.empty?
          Runtime::Logger.error("Scenario #{Runtime::Scenario.klass} has no specs to run!")
          Runtime::Logger.error("Check if all tests have been filtered out by custom spec pattern!")

          abort
        end

        if Runtime::Scenario.attributes[:count_examples_only]
          count_examples_only(full_arg_list)
        elsif Runtime::Scenario.attributes[:test_metadata_only]
          test_metadata_only(full_arg_list)
        elsif Runtime::Env.knapsack?
          KnapsackRunner.run(args, rspec_paths, example_data, parallel: run_in_parallel?) do |status|
            abort if status.nonzero?
          end
        elsif run_in_parallel?
          ParallelRunner.run(args, rspec_paths, example_data)
        elsif Runtime::Scenario.attributes[:loop]
          LoopRunner.run(full_arg_list)
        else
          RSpec::Core::Runner.run(full_arg_list, *DEFAULT_STD_ARGS).tap do |status|
            abort if status.nonzero?
          end
        end
      end

      def count_examples_only(args)
        args.unshift('--dry-run')
        out = StringIO.new
        err = StringIO.new

        total_examples = Tempfile.open('test-metadata.json') do |file|
          RSpec.configure { |config| config.add_formatter(QA::Support::JsonFormatter, file.path) }
          RSpec::Core::Runner.run(args.flatten, err, out).tap { |status| abort if status.nonzero? }

          JSON.load_file(file, symbolize_names: true).dig(:summary, :example_count)
        end

        puts total_examples
      rescue StandardError => e
        raise e, "Failed to detect example count, error: '#{e}'.\nOut: '#{out.string}'\nErr: #{err.string}"
      end

      # Trigger tests using parallel runner
      #
      # @return [Boolean]
      def run_in_parallel?
        return @parallel if defined?(@parallel)

        # Do not use parallel with retry as parallel_tests is not capable to correctly detect
        # groups of tests when `--only-failures` parameter is used
        @parallel = (Runtime::Scenario.attributes[:parallel] || Runtime::Env.run_in_parallel?) && !rspec_retried?
      end

      def test_metadata_only(args)
        args.unshift('--dry-run')

        output_file = Pathname.new(File.join(Runtime::Path.qa_root, 'tmp', 'test-metadata.json'))

        RSpec.configure do |config|
          config.add_formatter(QA::Support::JsonFormatter, output_file)
          config.fail_if_no_examples = true
        end

        RSpec::Core::Runner.run(args.flatten, $stderr, $stdout) do |status|
          abort if status.nonzero?
        end

        $stdout.puts "Saved to file: #{output_file}"
      end

      def configure_default_formatters!(args)
        default_formatter_file_name = "tmp/rspec-#{ENV['CI_JOB_ID'] || 'local'}-retried-#{rspec_retried?}"
        filename = if run_in_parallel?
                     rspec_retried? ? default_formatter_file_name : "#{default_formatter_file_name}-$TEST_ENV_NUMBER"
                   else
                     default_formatter_file_name
                   end

        args.push("--format", "documentation") unless args.flatten.include?("documentation")
        { "QA::Support::JsonFormatter" => "json", "RspecJunitFormatter" => "xml" }.each do |formatter, extension|
          next if args.flatten.include?(formatter)

          args.push("--format", formatter, "--out", "#{filename}.#{extension}")
        end
      end

      def metadata_run?
        Runtime::Scenario.attributes[:count_examples_only] || Runtime::Scenario.attributes[:test_metadata_only]
      end

      # Example ids with their execution status
      #
      # @return [Hash<String, String>]
      def example_data
        Support::ExampleData.fetch(rspec_tags).each_with_object({}) do |example, ids|
          ids[example[:id]] = example[:status]
        end
      end
    end
  end
end
