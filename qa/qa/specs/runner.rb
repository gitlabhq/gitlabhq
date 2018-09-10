require 'rspec/core'

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

        args.push(options)
        args.push(DEFAULT_TEST_PATH_ARGS) unless options.any? { |opt| opt =~ %r{/features/} }

        Runtime::Browser.configure!

        RSpec::Core::Runner.run(args.flatten, $stderr, $stdout).tap do |status|
          abort if status.nonzero?
        end
      end
    end
  end
end
