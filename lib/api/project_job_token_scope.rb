# frozen_string_literal: true

module API
  class ProjectJobTokenScope < ::API::Base
    before { authenticate! }

    feature_category :secrets_management
    urgency :low

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Fetch CI_JOB_TOKEN access settings.' do
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        success code: 200, model: Entities::ProjectJobTokenScope
        tags %w[projects_job_token_scope]
      end
      get ':id/job_token_scope' do
        authorize_admin_project

        present user_project, with: Entities::ProjectJobTokenScope
      end
    end
  end
end
