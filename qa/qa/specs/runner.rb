# frozen_string_literal: true

require 'knapsack'
require 'rspec/core'
require 'rspec/expectations'

module QA
  module Specs
    class Runner < Scenario::Template
      attr_accessor :tty, :tags, :options

      DEFAULT_TEST_PATH_ARGS = ['--', File.expand_path('./features', __dir__)].freeze

      def initialize
        @tty = false
        @tags = []
        @options = []
      end

      def paths_from_knapsack
        allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

        QA::Runtime::Logger.info ''
        QA::Runtime::Logger.info 'Report specs:'
        QA::Runtime::Logger.info allocator.report_node_tests.join(', ')
        QA::Runtime::Logger.info ''
        QA::Runtime::Logger.info 'Leftover specs:'
        QA::Runtime::Logger.info allocator.leftover_node_tests.join(', ')
        QA::Runtime::Logger.info ''

        ['--', allocator.node_tests]
      end

      def rspec_tags
        tags_for_rspec = []

        if tags.any?
          tags.each { |tag| tags_for_rspec.push(['--tag', tag.to_s]) }
        else
          tags_for_rspec.push(%w[--tag ~orchestrated]) unless (%w[-t --tag] & options).any?
        end

        tags_for_rspec.push(%w[--tag ~skip_signup_disabled]) if QA::Runtime::Env.signup_disabled?

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

        if Runtime::Scenario.attributes[:parallel]
          ParallelRunner.run(args.flatten)
        else
          RSpec::Core::Runner.run(args.flatten, $stderr, $stdout).tap do |status|
            abort if status.nonzero?
          end
        end
      end
    end
  end
end
