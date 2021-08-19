# frozen_string_literal: true

module Ci
  module PipelineEditorHelper
    include ChecksCollaboration

    def can_view_pipeline_editor?(project)
      can_collaborate_with_project?(project)
    end

    def js_pipeline_editor_data(project)
      initial_branch = params[:branch_name]
      latest_commit = project.repository.commit(initial_branch) || project.commit
      commit_sha = latest_commit ? latest_commit.sha : ''
      {
        "ci-config-path": project.ci_config_path_or_default,
        "ci-examples-help-page-path" => help_page_path('ci/examples/index'),
        "ci-help-page-path" => help_page_path('ci/index'),
        "commit-sha" => commit_sha,
        "default-branch" => project.default_branch_or_main,
        "empty-state-illustration-path" => image_path('illustrations/empty-state/empty-dag-md.svg'),
        "initial-branch-name" => initial_branch,
        "lint-help-page-path" => help_page_path('ci/lint', anchor: 'validate-basic-logic-and-syntax'),
        "needs-help-page-path" => help_page_path('ci/yaml/index', anchor: 'needs'),
        "new-merge-request-path" => namespace_project_new_merge_request_path,
        "pipeline_etag" => latest_commit ? graphql_etag_pipeline_sha_path(commit_sha) : '',
        "pipeline-page-path" => project_pipelines_path(project),
        "project-path" => project.path,
        "project-full-path" => project.full_path,
        "project-namespace" => project.namespace.full_path,
        "runner-help-page-path" => help_page_path('ci/runners/index'),
        "total-branches" => project.repository.branches.length,
        "yml-help-page-path" => help_page_path('ci/yaml/index')
      }
    end
  end
end

Ci::PipelineEditorHelper.prepend_mod_with('Ci::PipelineEditorHelper')
