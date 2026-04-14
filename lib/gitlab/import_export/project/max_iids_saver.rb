# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class MaxIidsSaver < BaseMaxIidsSaver
        RESOURCE_QUERIES = {
          issues: ->(project) { project.issues.maximum(:iid) },
          merge_requests: ->(project) { project.merge_requests.maximum(:iid) },
          project_milestones: ->(project) { project.milestones.maximum(:iid) },
          ci_pipelines: ->(project) { project.ci_pipelines.maximum(:iid) },
          design_management_designs: ->(project) { project.designs.maximum(:iid) }
        }.freeze

        def self.resource_queries
          RESOURCE_QUERIES
        end

        def initialize(project:, shared:)
          super(exportable: project, shared: shared)
        end
      end
    end
  end
end
