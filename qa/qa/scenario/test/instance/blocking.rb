# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class Blocking < Template
          include Bootable
          include SharedAttributes

          tags :reliable, :smoke
        end
      end
    end
  end
end
