# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class Airgapped < Template
          include Bootable
          include SharedAttributes
          def perform(address, *rspec_options)
            Runtime::Scenario.define(:network, 'airgapped')

            super
          end
        end
      end
    end
  end
end
