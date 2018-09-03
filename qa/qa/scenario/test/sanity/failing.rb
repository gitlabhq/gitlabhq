# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Sanity
        ##
        # This scenario exits with a 1 exit code.
        #
        class Failing < Template
          include Bootable

          tags :failing
        end
      end
    end
  end
end
