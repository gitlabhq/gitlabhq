# frozen_string_literal: true

module QA
  module Scenario
    module Test
      ##
      # Base class for running the suite against any GitLab instance,
      # including staging and on-premises installation.
      #
      module Instance
        class All < Template
          include Bootable
          include SharedAttributes

          pipeline_mappings test_on_cng: ['cng-instance'], test_on_gdk: ["gdk-instance"]
        end
      end
    end
  end
end
