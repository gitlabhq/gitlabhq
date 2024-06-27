# frozen_string_literal: true

module API
  class ProjectContainerRegistryProtectionRules < ::API::Base
    feature_category :container_registry

    after_validation do
      if Feature.disabled?(:container_registry_protected_containers, user_project)
        render_api_error!("'container_registry_protected_containers' feature flag is disabled", :not_found)
      end

      authenticate!
      authorize! :admin_container_image, user_project
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get list of container registry protection rules for a project' do
        success Entities::Projects::ContainerRegistry::Protection::Rule
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[projects]
        is_array true
        hidden true
      end
    end
    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      get ':id/registry/protection/rules' do
        present user_project.container_registry_protection_rules,
          with: Entities::Projects::ContainerRegistry::Protection::Rule
      end
    end
  end
end
