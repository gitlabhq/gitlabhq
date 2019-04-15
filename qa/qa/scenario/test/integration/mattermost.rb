# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        ##
        # Run test suite against any GitLab instance where mattermost is enabled,
        # including staging and on-premises installation.
        #
        class Mattermost < Test::Instance::All
          tags :mattermost

          attribute :mattermost_address, '--mattermost-address URL', 'Address of the Mattermost server'

          def perform(options, *args)
            extract_address(:gitlab_address, options, args)
            extract_address(:mattermost_address, options, args)

            super(options, *args)
          end
        end
      end
    end
  end
end
