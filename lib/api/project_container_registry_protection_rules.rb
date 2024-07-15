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

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource ':id/registry/protection/rules' do
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
        get do
          present user_project.container_registry_protection_rules,
            with: Entities::Projects::ContainerRegistry::Protection::Rule
        end

        desc 'Create a container protection rule for a project' do
          success Entities::Projects::ContainerRegistry::Protection::Rule
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' },
            { code: 422, message: 'Unprocessable Entity' }
          ]
          tags %w[projects]
          hidden true
        end
        params do
          requires :repository_path_pattern, type: String,
            desc: 'Container repository path pattern protected by the protection rule.
            For example `flight/flight-*`. Wildcard character `*` allowed.'
          optional :minimum_access_level_for_push, type: String,
            values: ContainerRegistry::Protection::Rule.minimum_access_level_for_pushes.keys,
            desc: 'Minimum GitLab access level to allow to push container images to the container registry.
            For example maintainer, owner or admin.'
          optional :minimum_access_level_for_delete, type: String,
            values: ContainerRegistry::Protection::Rule.minimum_access_level_for_deletes.keys,
            desc: 'Minimum GitLab access level to allow to delete container images in the container registry.
            For example maintainer, owner or admin.'
          at_least_one_of :minimum_access_level_for_push, :minimum_access_level_for_delete
        end
        post do
          response = ::ContainerRegistry::Protection::CreateRuleService.new(user_project,
            current_user, declared_params).execute

          render_api_error!({ error: response.message }, :unprocessable_entity) if response.error?

          present response[:container_registry_protection_rule],
            with: Entities::Projects::ContainerRegistry::Protection::Rule
        end

        params do
          requires :protection_rule_id, type: Integer,
            desc: 'The ID of the container protection rule'
        end
        resource ':protection_rule_id' do
          desc 'Update a container protection rule for a project' do
            success Entities::Projects::ContainerRegistry::Protection::Rule
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' },
              { code: 422, message: 'Unprocessable Entity' }
            ]
            tags %w[projects]
            hidden true
          end
          params do
            optional :repository_path_pattern, type: String,
              desc: 'Container repository path pattern protected by the protection rule.
              For example `flight/flight-*`. Wildcard character `*` allowed.'
            optional :minimum_access_level_for_push, type: String,
              values: ContainerRegistry::Protection::Rule.minimum_access_level_for_pushes.keys << "",
              desc: 'Minimum GitLab access level to allow to push container images to the container registry.
              For example maintainer, owner or admin. To unset the value, use an empty string `""`.'
            optional :minimum_access_level_for_delete, type: String,
              values: ContainerRegistry::Protection::Rule.minimum_access_level_for_deletes.keys << "",
              desc: 'Minimum GitLab access level to allow to delete container images in the container registry.
              For example maintainer, owner or admin. To unset the value, use an empty string `""`.'
          end
          patch do
            protection_rule = user_project.container_registry_protection_rules.find(params[:protection_rule_id])
            response = ::ContainerRegistry::Protection::UpdateRuleService.new(protection_rule,
              current_user: current_user, params: declared_params(include_missing: false)).execute

            render_api_error!({ error: response.message }, :unprocessable_entity) if response.error?

            present response[:container_registry_protection_rule],
              with: Entities::Projects::ContainerRegistry::Protection::Rule
          end
        end
      end
    end
  end
end
