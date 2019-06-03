# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'knapsack'

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

      def perform
        args = []
        args.push('--tty') if tty

        if tags.any?
          tags.each { |tag| args.push(['--tag', tag.to_s]) }
        else
          args.push(%w[--tag ~orchestrated]) unless (%w[-t --tag] & options).any?
        end

        args.push(%w[--tag ~skip_signup_disabled]) if QA::Runtime::Env.signup_disabled?

        QA::Runtime::Env.supported_features.each_key do |key|
          args.push(["--tag", "~requires_#{key}"]) unless QA::Runtime::Env.can_test? key
        end

        args.push(options)

        Runtime::Browser.configure!

        if Runtime::Env.knapsack?
          allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

          QA::Runtime::Logger.info ''
          QA::Runtime::Logger.info 'Report specs:'
          QA::Runtime::Logger.info allocator.report_node_tests.join(', ')
          QA::Runtime::Logger.info ''
          QA::Runtime::Logger.info 'Leftover specs:'
          QA::Runtime::Logger.info allocator.leftover_node_tests.join(', ')
          QA::Runtime::Logger.info ''

          args.push(['--', allocator.node_tests])
        else
          args.push(DEFAULT_TEST_PATH_ARGS) unless options.any? { |opt| opt =~ %r{/features/} }
        end

        RSpec::Core::Runner.run(args.flatten, $stderr, $stdout).tap do |status|
          abort if status.nonzero?
        end
      end
    end
  end
end
