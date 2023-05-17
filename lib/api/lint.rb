# frozen_string_literal: true

module API
  class Lint < ::API::Base
    feature_category :pipeline_composition

    helpers do
      def can_lint_ci?
        signup_unrestricted = Gitlab::CurrentSettings.signup_enabled? && !Gitlab::CurrentSettings.signup_limited?
        internal_user = current_user.present? && !current_user.external?
        is_developer = current_user.present? && current_user.projects.any? { |p| p.member?(current_user, Gitlab::Access::DEVELOPER) }

        signup_unrestricted || internal_user || is_developer
      end
    end

    namespace :ci do
      desc 'REMOVED: Validates the .gitlab-ci.yml content' do
        detail 'Checks if CI/CD YAML configuration is valid'
        success code: 200, model: Entities::Ci::Lint::Result
        tags %w[ci_lint]
      end
      params do
        requires :content, type: String, desc: 'The CI/CD configuration content'
        optional :include_merged_yaml, type: Boolean, desc: 'If the expanded CI/CD configuration should be included in the response'
        optional :include_jobs, type: Boolean, desc: 'If the list of jobs should be included in the response. This is
        false by default'
      end

      post '/lint', urgency: :low do
        render_api_error!('410 Gone', 410)
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Validates a CI YAML configuration with a namespace' do
        detail 'Checks if a project’s latest (HEAD of the project’s default branch) .gitlab-ci.yml configuration is
        valid'
        success Entities::Ci::Lint::Result
        tags %w[ci_lint]
      end
      params do
        optional :dry_run, type: Boolean, default: false, desc: 'Run pipeline creation simulation, or only do static check. This is false by default'
        optional :include_jobs, type: Boolean, desc: 'If the list of jobs that would exist in a static check or pipeline
        simulation should be included in the response. This is false by default'
        optional :ref, type: String, desc: 'Branch or tag used to execute a dry run. Defaults to the default branch of the project. Only used when dry_run is true'
      end

      get ':id/ci/lint', urgency: :low do
        authorize_read_code!

        if user_project.commit.present?
          content = user_project.repository.gitlab_ci_yml_for(user_project.commit.id, user_project.ci_config_path_or_default)
        end

        result = Gitlab::Ci::Lint
          .new(project: user_project, current_user: current_user)
          .validate(content, dry_run: params[:dry_run], ref: params[:ref] || user_project.default_branch)

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
