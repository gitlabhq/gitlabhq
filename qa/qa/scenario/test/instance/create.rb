# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class Create < All
          spec_glob_pattern "qa/specs/features/**/3_create/**/*_spec.rb"

          pipeline_mappings test_on_omnibus: %w[praefect gitaly-transactions gitaly-reftables-backend]
        end
      end
    end
  end
end
