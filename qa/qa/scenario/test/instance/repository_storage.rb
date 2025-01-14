# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Instance
        class RepositoryStorage < All
          tags :repository_storage

          pipeline_mappings test_on_omnibus: %w[repository-storage]
        end
      end
    end
  end
end
