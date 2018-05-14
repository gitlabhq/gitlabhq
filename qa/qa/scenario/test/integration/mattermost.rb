module QA
  module Scenario
    module Test
      module Integration
        ##
        # Run test suite against any GitLab instance where mattermost is enabled,
        # including staging and on-premises installation.
        #
        class Mattermost < Test::Instance
          tags :core, :mattermost

          def perform(address, mattermost, *rspec_options)
            Runtime::Scenario.define(:mattermost_address, mattermost)

            super(address, *rspec_options)
          end
        end
      end
    end
  end
end
