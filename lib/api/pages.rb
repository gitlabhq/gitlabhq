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
        authorize! :remove_pages, user_project

        ::Pages::DeleteService.new(user_project, current_user).execute

        no_content!
      end

      desc 'Update pages settings' do
        detail 'Update page settings for a project. User must have administrative access.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[pages]
      end
      params do
        optional :pages_unique_domain_enabled, type: Boolean, desc: 'Whether to use unique domain'
        optional :pages_https_only, type: Boolean, desc: 'Whether to force HTTPS'
        optional :pages_primary_domain, type: String, desc: 'Set pages primary domain'
      end
      patch ':id/pages' do
        authorize! :update_pages, user_project

        break not_found! unless user_project.pages_enabled?

        if params[:pages_primary_domain] &&
            !user_project.pages_domain_present?(params[:pages_primary_domain])
          bad_request!("The `pages_primary_domain` attribute is missing from the domain list " \
            "in the Pages project configuration. Assign `pages_primary_domain` to " \
            "the Pages project or reset it.")
        end

        response = ::Pages::UpdateService.new(user_project, current_user, params).execute

        if response.success?
          present ::Pages::ProjectSettings.new(response.payload[:project]), with: Entities::Pages::ProjectSettings
        else
          forbidden!(response.message)
        end
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
