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

          def perform(address, mattermost, *files)
            Runtime::Scenario.define(:mattermost_address, mattermost)

            super(address, *files)
          end
        end
      end
    end
  end
end
