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
      total_branches = project.repository_exists? ? project.repository.branch_count : 0

      {
        "ci-catalog-path" => explore_catalog_index_path,
        "ci-config-path": project.ci_config_path_or_default,
        "ci-examples-help-page-path" => help_page_path('ci/examples/_index.md'),
        "ci-help-page-path" => help_page_path('ci/_index.md'),
        "ci-lint-path" => project_ci_lint_path(project),
        "ci-troubleshooting-path" => help_page_path('ci/debugging.md', anchor: 'job-configuration-issues'),
        "default-branch" => project.default_branch_or_main,
        "empty-state-illustration-path" => image_path('illustrations/empty-state/empty-pipeline-md.svg'),
        "initial-branch-name" => initial_branch,
        "includes-help-page-path" => help_page_path('ci/yaml/includes.md'),
        "lint-help-page-path" => help_page_path('ci/yaml/lint.md', anchor: 'check-cicd-syntax'),
        "needs-help-page-path" => help_page_path('ci/yaml/_index.md', anchor: 'needs'),
        "new-merge-request-path" => namespace_project_new_merge_request_path,
        "pipeline_etag" => latest_commit ? graphql_etag_pipeline_sha_path(latest_commit.sha) : '',
        "pipeline-page-path" => project_pipelines_path(project),
        "project-path" => project.path,
        "project-full-path" => project.full_path,
        "project-namespace" => project.namespace.full_path,
        "simulate-pipeline-help-page-path" => help_page_path('ci/pipeline_editor/_index.md', anchor: 'simulate-a-cicd-pipeline'),
        "total-branches" => total_branches,
        "uses-external-config" => uses_external_config?(project) ? 'true' : 'false',
        "validate-tab-illustration-path" => image_path('illustrations/empty-state/empty-devops-md.svg'),
        "yml-help-page-path" => help_page_path('ci/yaml/_index.md')
      }
    end

    private

    def uses_external_config?(project)
      ci_config_source = Gitlab::Ci::ProjectConfig.new(project: project, sha: nil).source

      [:external_project_source, :remote_source].include?(ci_config_source)
    end
  end
end

Ci::PipelineEditorHelper.prepend_mod_with('Ci::PipelineEditorHelper')
