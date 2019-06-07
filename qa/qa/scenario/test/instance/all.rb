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
        end
      end
    end
  end
end
