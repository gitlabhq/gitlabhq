require 'rspec/core'

module QA
  module Specs
    class Runner
      include Scenario::Actable

      def rspec(*args)
        RSpec::Core::Runner.run(args.flatten, $stderr, $stdout).tap do |status|
          abort if status.nonzero?
        end
      end
    end
  end
end
