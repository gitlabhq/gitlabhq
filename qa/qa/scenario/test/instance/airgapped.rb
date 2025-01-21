# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class Airgapped < Template
          include Bootable
          include SharedAttributes

          tags "~github", "~external_api_calls", "~skip_live_env", *Specs::Runner::DEFAULT_SKIPPED_TAGS

          pipeline_mappings test_on_omnibus_nightly: ["airgapped"]

          def perform(address, *rspec_options)
            Runtime::Scenario.define(:network, 'airgapped')

            super
          end
        end
      end
    end
  end
end
