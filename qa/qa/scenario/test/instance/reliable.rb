# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class Reliable < Template
          include Bootable
          include SharedAttributes

          tags :reliable
        end
      end
    end
  end
end
