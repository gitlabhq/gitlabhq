# frozen_string_literal: true

module API
  class Lint < ::API::Base
    feature_category :pipeline_authoring

    helpers do
      def can_lint_ci?
        signup_unrestricted = Gitlab::CurrentSettings.signup_enabled? && !Gitlab::CurrentSettings.signup_limited?
        internal_user = current_user.present? && !current_user.external?
        is_developer = current_user.present? && current_user.projects.any? { |p| p.team.member?(current_user, Gitlab::Access::DEVELOPER) }

        signup_unrestricted || internal_user || is_developer
      end
    end

    namespace :ci do
      desc 'Validation of .gitlab-ci.yml content'
      params do
        requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
        optional :include_merged_yaml, type: Boolean, desc: 'Whether or not to include merged CI config yaml in the response'
        optional :include_jobs, type: Boolean, desc: 'Whether or not to include CI jobs in the response'
      end
      post '/lint' do
        unauthorized! unless can_lint_ci?

        result = Gitlab::Ci::Lint.new(project: nil, current_user: current_user)
          .validate(params[:content], dry_run: false)

        status 200
        Entities::Ci::Lint::Result.represent(result, current_user: current_user, include_jobs: params[:include_jobs]).serializable_hash.tap do |presented_result|
          presented_result[:status] = presented_result[:valid] ? 'valid' : 'invalid'
          presented_result.delete(:merged_yaml) unless params[:include_merged_yaml]
        end
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Validation of .gitlab-ci.yml content' do
        detail 'This feature was introduced in GitLab 13.5.'
      end
      params do
        optional :dry_run, type: Boolean, default: false, desc: 'Run pipeline creation simulation, or only do static check.'
        optional :include_jobs, type: Boolean, desc: 'Whether or not to include CI jobs in the response'
      end
      get ':id/ci/lint' do
        authorize! :download_code, user_project

        content = user_project.repository.gitlab_ci_yml_for(user_project.commit.id, user_project.ci_config_path_or_default)
        result = Gitlab::Ci::Lint
          .new(project: user_project, current_user: current_user)
          .validate(content, dry_run: params[:dry_run])

        present result, with: Entities::Ci::Lint::Result, current_user: current_user, include_jobs: params[:include_jobs]
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Validation of .gitlab-ci.yml content' do
        detail 'This feature was introduced in GitLab 13.6.'
      end
      params do
        requires :content, type: String, desc: 'Content of .gitlab-ci.yml'
        optional :dry_run, type: Boolean, default: false, desc: 'Run pipeline creation simulation, or only do static check.'
        optional :include_jobs, type: Boolean, desc: 'Whether or not to include CI jobs in the response'
      end
      post ':id/ci/lint' do
        authorize! :create_pipeline, user_project

        result = Gitlab::Ci::Lint
          .new(project: user_project, current_user: current_user)
          .validate(params[:content], dry_run: params[:dry_run])

        status 200
        present result, with: Entities::Ci::Lint::Result, current_user: current_user, include_jobs: params[:include_jobs]
      end
    end
  end
end
