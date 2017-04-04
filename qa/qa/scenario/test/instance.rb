module QA
  module Scenario
    module Test
      ##
      # Run test suite against any GitLab instance,
      # including staging and on-premises installation.
      #
      class Instance < Scenario::Template
        def perform(address, *files)
          Specs::Config.perform do |specs|
            specs.address = address
          end

          ##
          # Perform before hooks, which are different for CE and EE
          #
          Runtime::Release.perform_before_hooks

          Specs::Runner.perform do |specs|
            specs.rspec('--tty', files.any? ? files : 'qa/specs/features')
          end
        end
      end
    end
  end
end
