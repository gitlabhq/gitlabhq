module QA
  module Scenario
    module Test
      module Integration
        ##
        # Run test suite against any GitLab instance where mattermost is enabled,
        # including staging and on-premises installation.
        #
        class Mattermost < Scenario::Entrypoint
          protected

          def configure_specs(specs)
            specs.exclusion_filter[:mattermost] = false
          end
        end
      end
    end
  end
end
