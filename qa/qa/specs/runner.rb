require 'rspec/core'

module QA
  module Specs
    class Runner
      include Scenario::Actable

      def rspec(tty: false, tags: [], files: ['qa/specs/features'])
        args = []
        args << '--tty' if tty
        tags.to_a.each do |tag|
          args << ['-t', tag.to_s]
        end
        args << files

        RSpec::Core::Runner.run(args.flatten, $stderr, $stdout).tap do |status|
          abort if status.nonzero?
        end
      end
    end
  end
end
