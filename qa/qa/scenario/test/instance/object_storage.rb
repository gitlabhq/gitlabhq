# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class ObjectStorage < All
          tags :object_storage

          pipeline_mappings test_on_omnibus_nightly: %w[object-storage object-storage-aws object-storage-gcs]
        end
      end
    end
  end
end
