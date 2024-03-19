# frozen_string_literal: true

module API
  class Lint < ::API::Base
    feature_category :pipeline_composition

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Validates a CI YAML configuration with a namespace' do
        detail 'Checks if a project’s .gitlab-ci.yml configuration in a given commit (by default HEAD of the
        project’s default branch) is valid'
        success Entities::Ci::Lint::Result
        tags %w[ci_lint]
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        optional :sha, type: String, desc: 'Deprecated: Use content_ref instead'
        optional :content_ref, type: String, desc: "The CI/CD configuration content is taken from this commit SHA, branch or tag. Defaults to the HEAD of the project's default branch"
        mutually_exclusive :sha, :content_ref

        optional :dry_run, type: Boolean, default: false, desc: 'Run pipeline creation simulation, or only do static check. This is false by default'
        optional :include_jobs, type: Boolean, desc: 'If the list of jobs that would exist in a static check or pipeline
        simulation should be included in the response. This is false by default'

        optional :ref, type: String, desc: 'Deprecated: Use dry_run_ref instead'
        optional :dry_run_ref, type: String, desc: 'Branch or tag used as context when executing a dry run. Defaults to the default branch of the project. Only used when dry_run is true'
        mutually_exclusive :ref, :dry_run_ref
      end

      get ':id/ci/lint', urgency: :low do
        authorize_read_code!

        not_found! 'Repository' if user_project.empty_repo?

        content_ref = params[:content_ref] || params[:sha] || user_project.repository.root_ref_sha
        dry_run_ref = params[:dry_run_ref] || params[:ref] || user_project.default_branch

        commit = user_project.commit(content_ref)
        not_found! 'Commit' unless commit.present?

        content = user_project.repository.blob_data_at(commit.sha, user_project.ci_config_path_or_default)
        result = Gitlab::Ci::Lint
          .new(project: user_project, current_user: current_user, sha: commit.sha)
          .validate(content, dry_run: params[:dry_run], ref: dry_run_ref)

        present result, with: Entities::Ci::Lint::Result, current_user: current_user, include_jobs: params[:include_jobs]
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Validate a CI YAML configuration with a namespace' do
        detail 'Checks if CI/CD YAML configuration is valid. This endpoint has namespace specific context'
        success code: 200, model: Entities::Ci::Lint::Result
        tags %w[ci_lint]
      end
      params do
        requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
        optional :dry_run, type: Boolean, default: false, desc: 'Run pipeline creation simulation, or only do static check. This is false by default'
        optional :include_jobs, type: Boolean, desc: 'If the list of jobs that would exist in a static check or pipeline
        simulation should be included in the response. This is false by default'
        optional :ref, type: String, desc: 'When dry_run is true, sets the branch or tag to use. Defaults to the project’s default branch when not set'
      end

      post ':id/ci/lint', urgency: :low do
        authorize! :create_pipeline, user_project

        result = Gitlab::Ci::Lint
          .new(project: user_project, current_user: current_user)
          .validate(params[:content], dry_run: params[:dry_run], ref: params[:ref] || user_project.default_branch)

        status 200
        present result, with: Entities::Ci::Lint::Result, current_user: current_user, include_jobs: params[:include_jobs]
      end
    end
  end
end
