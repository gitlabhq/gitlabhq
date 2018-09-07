# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Sanity
        ##
        # This scenario runs 1 passing example, and 1 failing example, and exits
        # with a 1 exit code.
        #
        class Framework < Template
          include Bootable

          tags :framework
        end
      end
    end
  end
end
