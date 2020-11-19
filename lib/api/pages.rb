# frozen_string_literal: true

module API
  class Pages < ::API::Base
    feature_category :pages

    before do
      require_pages_config_enabled!
      authenticated_with_can_read_all_resources!
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

        ::Pages::DeleteService.new(user_project, current_user).execute

        no_content!
      end
    end
  end
end
