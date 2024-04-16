# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'

module QA
  module Specs
    class Runner < Scenario::Template
      attr_accessor :tty, :tags, :options

      RegexMismatchError = Class.new(StandardError)

      DEFAULT_TEST_PATH_ARGS = ['--', File.expand_path('./features', __dir__)].freeze
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
        tags_for_rspec.push(%w[--tag ~smoke --tag ~reliable]) if QA::Runtime::Env.skip_smoke_reliable?
        tags_for_rspec.push(%w[--tag ~skip_live_env]) if QA::Specs::Helpers::ContextSelector.dot_com?

        QA::Runtime::Env.supported_features.each_key do |key|
          tags_for_rspec.push(%W[--tag ~requires_#{key}]) unless QA::Runtime::Env.can_test? key
        end

        tags_for_rspec
      end

      def perform
        args = []
        args.push('--tty') if tty
        args.push(rspec_tags)
        args.push(options)

        unless Runtime::Env.knapsack? || options.any? { |opt| opt.include?('features') }
          args.push(DEFAULT_TEST_PATH_ARGS)
        end

        if Runtime::Env.knapsack?
          KnapsackRunner.run(args.flatten) { |status| abort if status.nonzero? }
        elsif Runtime::Scenario.attributes[:parallel]
          ParallelRunner.run(args.flatten)
        elsif Runtime::Scenario.attributes[:loop]
          LoopRunner.run(args.flatten)
        elsif Runtime::Scenario.attributes[:count_examples_only]
          count_examples_only(args)
        elsif Runtime::Scenario.attributes[:test_metadata_only]
          test_metadata_only(args)
        else
          RSpec::Core::Runner.run(args.flatten, *DEFAULT_STD_ARGS).tap { |status| abort if status.nonzero? }
        end
      end

      private

      def count_examples_only(args)
        args.unshift('--dry-run')
        out = StringIO.new

        RSpec::Core::Runner.run(args.flatten, $stderr, out).tap do |status|
          abort if status.nonzero?
        end

        begin
          total_examples = out.string.match(/(\d+) examples?,/)[1]
        rescue StandardError
          raise RegexMismatchError, 'Rspec output did not match regex'
        end

        filename = build_filename

        File.open(filename, 'w') { |f| f.write(total_examples) } if total_examples.to_i > 0

        $stdout.puts total_examples
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

      def build_filename
        filename = Runtime::Scenario.klass.split('::').last(3).join('_').downcase

        tags = []
        tag_opts = %w[--tag -t]
        options.reduce do |before, after|
          tags << after if tag_opts.include?(before)
          after
        end
        tags = tags.compact.join('_')

        filename.concat("_#{tags}") unless tags.empty?

        filename.concat('.txt')

        FileUtils.mkdir_p('no_of_examples')
        File.join('no_of_examples', filename)
      end
    end
  end
end
