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

          pipeline_mappings test_on_cng: %w[cng-instance],
            test_on_gdk: %w[gdk-instance gdk-instance-gitaly-transactions gdk-instance-ff-inverse],
            test_on_omnibus: %w[instance git-sha256-repositories],
            test_on_omnibus_nightly: %w[
              instance-image-slow-network
              nplus1-instance-image
              relative-url
              decomposition-single-db
              decomposition-multiple-db
            ]
        end
      end
    end
  end
end
