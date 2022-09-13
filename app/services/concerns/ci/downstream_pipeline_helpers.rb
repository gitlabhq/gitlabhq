# frozen_string_literal: true

module Ci
  module DownstreamPipelineHelpers
    def log_downstream_pipeline_creation(downstream_pipeline)
      return unless downstream_pipeline&.persisted?

      root_pipeline = downstream_pipeline.upstream_root

      ::Gitlab::AppLogger.info(
        message: "downstream pipeline created",
        class: self.class.name,
        root_pipeline_id: root_pipeline.id,
        downstream_pipeline_id: downstream_pipeline.id,
        downstream_pipeline_relationship: downstream_pipeline.parent_pipeline? ? :parent_child : :multi_project,
        hierarchy_size: downstream_pipeline.complete_hierarchy_count,
        root_pipeline_plan: root_pipeline.project.actual_plan_name,
        root_pipeline_namespace_path: root_pipeline.project.namespace.full_path,
        root_pipeline_project_path: root_pipeline.project.full_path
      )
    end
  end
end
