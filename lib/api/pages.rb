# frozen_string_literal: true

module API
  class Pages < ::API::Base
    feature_category :pages

    before do
      require_pages_config_enabled!
      authenticated_with_can_read_all_resources!
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
        authorize! :remove_pages, user_project

        ::Pages::DeleteService.new(user_project, current_user).execute

        no_content!
      end
    end
  end
end
