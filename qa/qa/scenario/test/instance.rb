module QA
  module Scenario
    module Test
      ##
      # Run test suite against any GitLab instance,
      # including staging and on-premises installation.
      #
      class Instance < Entrypoint
        tags :core
      end
    end
  end
end
