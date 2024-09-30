# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'tempfile'

module QA
  module Specs
    class Runner < Scenario::Template
      attr_accessor :tty, :tags, :options

      RegexMismatchError = Class.new(StandardError)

      DEFAULT_TEST_PATH_ARGS = [
        '--',
        File.expand_path('./features', __dir__),
        GitlabEdition.jh? ? File.expand_path('../../.././jh/qa/qa/specs/features', __dir__) : nil
      ].compact.freeze
      DEFAULT_STD_ARGS = [$stderr, $stdout].freeze
      DEFAULT_SKIPPED_TAGS = %w[orchestrated transient].freeze

      def initialize
        @tty = false
        @tags = []
        @options = []
      end

      def rspec_tags
        tags_for_rspec = []

        return tags_for_rspec if Runtime::Scenario.attributes[:test_metadata_only] || Runtime::Env.rspec_retried?

        if tags.any?
          tags.each { |tag| tags_for_rspec.push(['--tag', tag.to_s]) }
        else
          tags_for_rspec.push(DEFAULT_SKIPPED_TAGS.map { |tag| %W[--tag ~#{tag}] }) unless (%w[-t --tag] & options).any?
        end

        tags_for_rspec.push(%w[--tag ~geo]) unless QA::Runtime::Env.geo_environment?
        tags_for_rspec.push(%w[--tag ~skip_signup_disabled]) if QA::Runtime::Env.signup_disabled?
        tags_for_rspec.push(%w[--tag ~skip_live_env]) if QA::Specs::Helpers::ContextSelector.dot_com?

        QA::Runtime::Env.supported_features.each_key do |key|
          tags_for_rspec.push(%W[--tag ~requires_#{key}]) unless QA::Runtime::Env.can_test? key
        end

        tags_for_rspec
      end

      def perform
        args = build_initial_args
        # use options from default .rspec file for metadata only runs
        configure_default_formatters!(args) unless metadata_run?
        args.push(DEFAULT_TEST_PATH_ARGS) unless custom_test_paths?

        run_rspec(args)
      end

      private

      delegate :rspec_retried?, :parallel_run?, to: Runtime::Env

      def build_initial_args
        [].tap do |args|
          args.push('--tty') if tty
          args.push(rspec_tags)
          args.push(options)
        end
      end

      def run_rspec(args)
        if Runtime::Scenario.attributes[:count_examples_only]
          count_examples_only(args)
        elsif Runtime::Scenario.attributes[:test_metadata_only]
          test_metadata_only(args)
        elsif Runtime::Env.knapsack?
          KnapsackRunner.run(args.flatten, parallel: parallel_run?) { |status| abort if status.nonzero? }
        elsif !rspec_retried? && parallel_run?
          ParallelRunner.run(args.flatten)
        elsif Runtime::Scenario.attributes[:loop]
          LoopRunner.run(args.flatten)
        else
          RSpec::Core::Runner.run(args.flatten, *DEFAULT_STD_ARGS).tap { |status| abort if status.nonzero? }
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
        filename = if parallel_run?
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

      def custom_test_paths?
        Runtime::Env.knapsack? || options.any? { |opt| opt.include?('features') }
      end

      def metadata_run?
        Runtime::Scenario.attributes[:count_examples_only] || Runtime::Scenario.attributes[:test_metadata_only]
      end
    end
  end
end
