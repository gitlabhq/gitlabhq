# frozen_string_literal: true

module API
  class Lint < ::API::Base
    feature_category :pipeline_composition
    include APIGuard

    allow_access_with_scope :ai_workflows, if: ->(request) do
      request.post?
    end

    rescue_from ::Gitlab::Ci::Lint::RateLimitError do
      too_many_requests!(
        { error: ::Gitlab::ApplicationRateLimiter.throttled_error_message },
        retry_after: ::Gitlab::ApplicationRateLimiter.period_for(:ci_lint)
      )
    end

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Validate existing CI/CD configuration' do
        detail 'Validates the `.gitlab-ci.yml` configuration for a specified project.'
        success Entities::Ci::Lint::Result
        tags %w[ci_lint]
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        optional :sha, type: String, desc: "Commit SHA, branch, or tag that the CI/CD configuration content is taken from. Defaults to the head of the project's default branch. Deprecated. Use `content_ref` instead."
        optional :content_ref, type: String, desc: "Commit SHA, branch, or tag that the CI/CD configuration content is taken from. Defaults to the head of the project's default branch."
        mutually_exclusive :sha, :content_ref

        optional :dry_run, type: Boolean, default: false, desc: 'If `true`, runs a [pipeline creation simulation](https://docs.gitlab.com/ci/yaml/lint/#simulate-a-pipeline). If `false`, runs only a static check.'
        optional :include_jobs, type: Boolean, desc: 'If `true`, includes the list of jobs that would exist in a static check or pipeline simulation.'

        optional :ref, type: String, desc: "If `dry_run` is `true`, sets the branch or tag to use to validate the CI/CD YAML configuration. Defaults to the project's default branch. Deprecated. Use `dry_run_ref` instead."
        optional :dry_run_ref, type: String, desc: "If `dry_run` is `true`, sets the branch or tag to use to validate the CI/CD YAML configuration. Defaults to the project's default branch."
        mutually_exclusive :ref, :dry_run_ref
      end

      route_setting :authorization, permissions: :read_ci_config, boundary_type: :project
      get ':id/ci/lint', urgency: :low do
        authorize_read_code!

        not_found! 'Repository' if user_project.empty_repo?

        unauthorized!("This endpoint requires an API authentication") if current_user && !::Current.token_info

        content_ref = params[:content_ref] || params[:sha] || user_project.repository.root_ref_sha
        dry_run_ref = params[:dry_run_ref] || params[:ref] || user_project.default_branch

        commit = user_project.commit(content_ref)
        not_found! 'Commit' unless commit.present?

        content = user_project.repository.blob_data_at(commit.sha, user_project.ci_config_path_or_default)
        result = Gitlab::Ci::Lint
          .new(project: user_project, current_user: current_user, sha: commit.sha, surface: :rest_get)
          .legacy_validate(content, dry_run: params[:dry_run], ref: dry_run_ref)

        present result, with: Entities::Ci::Lint::Result, current_user: current_user, include_jobs: params[:include_jobs]
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Validate a CI/CD configuration' do
        detail 'Validates a provided CI/CD configuration in the context of a specified project.'
        success code: 200, model: Entities::Ci::Lint::Result
        tags %w[ci_lint]
      end
      params do
        requires :content, type: String, desc: 'CI/CD configuration content.'
        optional :dry_run, type: Boolean, default: false, desc: 'If `true`, runs a [pipeline creation simulation](https://docs.gitlab.com/ci/yaml/lint/#simulate-a-pipeline). If `false`, runs only a static check.'
        optional :include_jobs, type: Boolean, desc: 'If `true`, includes the list of jobs that would exist in a static check or pipeline simulation.'
        optional :ref, type: String, desc: "If `dry_run` is `true`, sets the branch or tag to use to validate the CI/CD YAML configuration. Defaults to the project's default branch."
      end

      route_setting :authorization, permissions: :validate_ci_config, boundary_type: :project
      post ':id/ci/lint', urgency: :low do
        authorize! :create_pipeline, user_project

        result = Gitlab::Ci::Lint
          .new(project: user_project, current_user: current_user, surface: :rest_post)
          .legacy_validate(params[:content], dry_run: params[:dry_run], ref: params[:ref] || user_project.default_branch)

        status 200
        present result, with: Entities::Ci::Lint::Result, current_user: current_user, include_jobs: params[:include_jobs]
      end
    end
  end
end
