# frozen_string_literal: true

module API
  class Pages < Grape::API
    before do
      require_pages_config_enabled!
      authenticated_with_full_private_access!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Unpublish pages' do
        detail 'This feature was introduced in GitLab 12.6'
      end
      delete ':id/pages' do
        authorize! :remove_pages, user_project

        status 204

        ::Pages::DeleteService.new(user_project, current_user).execute
      end
    end
  end
end
