# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Integration
        class GitalyCluster < Test::Instance::All
          tags :gitaly_cluster

          pipeline_mappings test_on_omnibus: %w[gitaly-cluster]
        end
      end
    end
  end
end
