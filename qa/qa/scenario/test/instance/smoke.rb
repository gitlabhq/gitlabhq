module QA
  module Scenario
    module Test
      module Instance
        ##
        # Base class for running the suite against any GitLab instance,
        # including staging and on-premises installation.
        #
        class Smoke < Template
          include Bootable

          tags :smoke
        end
      end
    end
  end
end
