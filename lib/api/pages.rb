# frozen_string_literal: true

module API
  class Pages < ::API::Base
    feature_category :pages

    before do
      require_pages_config_enabled!
    end

    params do
      requires :id, types: [String, Integer],
                    desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Unpublish pages' do
        detail 'Remove pages. The user must have administrator access. This feature was introduced in GitLab 12.6'
        success code: 204
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[pages]
      end
      delete ':id/pages' do
        authenticated_with_can_read_all_resources!
        authorize! :remove_pages, user_project

        ::Pages::DeleteService.new(user_project, current_user).execute

        no_content!
      end

      desc 'Get pages settings' do
        detail 'Get pages URL and other settings. This feature was introduced in Gitlab 16.8'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[pages]
      end
      get ':id/pages' do
        authorize! :read_pages, user_project

        break not_found! unless user_project.pages_enabled?

        present ::Pages::ProjectSettings.new(user_project), with: Entities::Pages::ProjectSettings
      end
    end
  end
end
