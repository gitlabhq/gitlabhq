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

      def initialize
        @tty = false
        @tags = []
        @options = []
      end

      def paths_from_knapsack
        allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

        QA::Runtime::Logger.info '==== Knapsack specs to execute ====='
        QA::Runtime::Logger.info 'Report specs:'
        QA::Runtime::Logger.info allocator.report_node_tests.join(', ')
        QA::Runtime::Logger.info 'Leftover specs:'
        QA::Runtime::Logger.info allocator.leftover_node_tests.join(', ')

        ['--', allocator.node_tests]
      end

      def rspec_tags
        tags_for_rspec = []

        if tags.any?
          tags.each { |tag| tags_for_rspec.push(['--tag', tag.to_s]) }
        else
          tags_for_rspec.push(%w[--tag ~orchestrated --tag ~transient]) unless (%w[-t --tag] & options).any?
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
        args = []
        args.push('--tty') if tty
        args.push(rspec_tags)
        args.push(options)

        if Runtime::Env.knapsack?
          args.push(paths_from_knapsack)
        else
          args.push(DEFAULT_TEST_PATH_ARGS) unless options.any? { |opt| opt =~ %r{/features/} }
        end

        Runtime::Scenario.define(:large_setup?, args.flatten.include?('can_use_large_setup'))

        if Runtime::Scenario.attributes[:parallel]
          ParallelRunner.run(args.flatten)
        elsif Runtime::Scenario.attributes[:loop]
          LoopRunner.run(args.flatten)
        elsif Runtime::Scenario.attributes[:count_examples_only]
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

          $stdout.puts "Total examples in #{Runtime::Scenario.klass}: #{total_examples}#{total_examples.to_i > 0 ? ". Saved to file: #{filename}" : ''}"
        else
          RSpec::Core::Runner.run(args.flatten, *DEFAULT_STD_ARGS).tap do |status|
            abort if status.nonzero?
          end
        end
      end

      private

      def build_filename
        filename = Runtime::Scenario.klass.split('::').last(3).join('_').downcase

        tags = []
        options.reduce do |before, after|
          tags << after if %w[--tag -t].include?(before)
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
