# frozen_string_literal: true

module API
  class ProjectContainerRegistryProtectionTagRules < ::API::Base
    feature_category :container_registry

    after_validation do
      authenticate!
      authorize! :admin_container_image, user_project
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project.'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource ':id/registry/protection/tag/rules' do
        desc 'Gets a list of container protection tag rules for a project' do
          detail 'This feature was introduced in GitLab 18.7.'
          success Entities::Projects::ContainerRegistry::Protection::TagRule
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[projects]
          is_array true
        end
        get do
          present user_project.container_registry_protection_tag_rules.mutable,
            with: Entities::Projects::ContainerRegistry::Protection::TagRule
        end
      end
    end
  end
end
