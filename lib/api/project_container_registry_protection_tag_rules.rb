# frozen_string_literal: true

module API
  class ProjectContainerRegistryProtectionTagRules < ::API::Base
    feature_category :container_registry

    after_validation do
      authenticate!
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project.'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource ':id/registry/protection/tag/rules' do
        desc 'Gets a list of container protection tag rules for a project.' do
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
          authorize! :admin_container_image, user_project

          present user_project.container_registry_protection_tag_rules.mutable,
            with: Entities::Projects::ContainerRegistry::Protection::TagRule
        end

        desc 'Create a container protection tag rule for a project. 5 rule limit per project.' do
          detail 'This feature was introduced in GitLab 18.8.'
          success Entities::Projects::ContainerRegistry::Protection::TagRule
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' },
            { code: 422, message: 'Unprocessable Entity' }
          ]
          tags %w[projects]
        end
        params do
          requires :tag_name_pattern, type: String,
            desc: 'Container tag name pattern protected by the protection rule. ' \
              'For example, `v*-release`. Wildcard character `*` allowed.'
          requires :minimum_access_level_for_push, type: String,
            values: ContainerRegistry::Protection::TagRule.minimum_access_level_for_pushes.keys,
            desc: 'Minimum GitLab access level required to push container tags. ' \
              'For example, Maintainer, Owner, or Admin.'
          requires :minimum_access_level_for_delete, type: String,
            values: ContainerRegistry::Protection::TagRule.minimum_access_level_for_deletes.keys,
            desc: 'Minimum GitLab access level required to delete container tags. ' \
              'For example, Maintainer, Owner, or Admin.'
        end
        post do
          authorize! :admin_container_image, user_project

          response =
            ::ContainerRegistry::Protection::CreateTagRuleService
              .new(project: user_project, current_user: current_user, params: declared_params)
              .execute

          render_api_error!(response.message, :unprocessable_entity) if response.error?

          present response[:container_protection_tag_rule],
            with: Entities::Projects::ContainerRegistry::Protection::TagRule
        end

        params do
          requires :protection_rule_id, type: Integer,
            desc: 'The ID of the container protection tag rule.'
        end
        resource ':protection_rule_id' do
          desc 'Update a container protection tag rule for a project.' do
            detail 'This feature was introduced in GitLab 18.9.'
            success Entities::Projects::ContainerRegistry::Protection::TagRule
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' },
              { code: 422, message: 'Unprocessable Entity' }
            ]
            tags %w[projects]
          end
          params do
            optional :tag_name_pattern, type: String,
              desc: 'Container tag name pattern protected by the protection rule. ' \
                'For example, `v*-release`. Wildcard character `*` allowed.'
            optional :minimum_access_level_for_push, type: String,
              values: ContainerRegistry::Protection::TagRule.minimum_access_level_for_pushes.keys << "",
              desc: 'Minimum GitLab access level required to push container tags. ' \
                'For example, Maintainer, Owner, or Admin. To unset the value, use an empty string (`""`).'
            optional :minimum_access_level_for_delete, type: String,
              values: ContainerRegistry::Protection::TagRule.minimum_access_level_for_deletes.keys << "",
              desc: 'Minimum GitLab access level required to delete container tags. ' \
                'For example, Maintainer, Owner, or Admin. To unset the value, use an empty string (`""`).'
          end
          patch do
            authorize! :admin_container_image, user_project

            protection_rule = user_project.container_registry_protection_tag_rules.find(params[:protection_rule_id])
            response = ::ContainerRegistry::Protection::UpdateTagRuleService.new(protection_rule,
              current_user: current_user, params: declared_params(include_missing: false)).execute

            render_api_error!({ error: response.message }, :unprocessable_entity) if response.error?

            present response[:container_protection_tag_rule],
              with: Entities::Projects::ContainerRegistry::Protection::TagRule
          end

          desc 'Delete container protection tag rule' do
            detail 'This feature was introduced in GitLab 18.9.'
            success code: 204, message: 'Delete a container protection tag rule'
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[projects]
          end
          delete do
            protection_rule = user_project.container_registry_protection_tag_rules.find(params[:protection_rule_id])

            authorize! :destroy_container_registry_protection_tag_rule, protection_rule

            destroy_conditionally!(protection_rule) do |protection_rule|
              response = ::ContainerRegistry::Protection::DeleteTagRuleService.new(protection_rule,
                current_user: current_user).execute

              render_api_error!({ error: response.message }, :bad_request) if response.error?
            end
          end
        end
      end
    end
  end
end
