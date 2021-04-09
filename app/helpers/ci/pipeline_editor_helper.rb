# frozen_string_literal: true

module Ci
  module PipelineEditorHelper
    include ChecksCollaboration

    def can_view_pipeline_editor?(project)
      can_collaborate_with_project?(project)
    end

    def js_pipeline_editor_data(project)
      {
        "ci-config-path": project.ci_config_path_or_default,
        "commit-sha" => project.commit ? project.commit.sha : '',
        "default-branch" => project.default_branch,
        "empty-state-illustration-path" => image_path('illustrations/empty-state/empty-dag-md.svg'),
        "initial-branch-name": params[:branch_name],
        "lint-help-page-path" => help_page_path('ci/lint', anchor: 'validate-basic-logic-and-syntax'),
        "new-merge-request-path" => namespace_project_new_merge_request_path,
        "project-path" => project.path,
        "project-full-path" => project.full_path,
        "project-namespace" => project.namespace.full_path,
        "yml-help-page-path" => help_page_path('ci/yaml/README')
      }
    end
  end
end

Ci::PipelineEditorHelper.prepend_if_ee('EE::Ci::PipelineEditorHelper')
