module QA
  module Scenario
    module Test
      ##
      # Base class for running the suite against any GitLab instance,
      # including staging and on-premises installation.
      #
      class Instance
        include Gitlab::QA::Framework::Scenario::Template
        include Gitlab::QA::Framework::Scenario::Taggable

        tags :core

        def perform(address, *rspec_options)
          Gitlab::QA::Framework::Runtime::Scenario.define(:gitlab_address, address)

          ##
          # Perform before hooks, which are different for CE and EE
          #
          Runtime::Release.perform_before_hooks

          Gitlab::QA::Framework::Scenario::Runner.perform do |specs|
            specs.tty = true
            specs.tags = self.class.focus
            specs.options =
              if rspec_options.any?
                rspec_options
              else
                File.expand_path('../../../scenarios', __dir__)
              end
          end
        end
      end
    end
  end
end
