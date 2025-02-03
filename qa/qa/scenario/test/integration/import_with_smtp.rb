# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class ImportWithSMTP < Test::Instance::All
          tags :import_with_smtp

          pipeline_mappings test_on_omnibus: %w[import-with-smtp]
        end
      end
    end
  end
end
