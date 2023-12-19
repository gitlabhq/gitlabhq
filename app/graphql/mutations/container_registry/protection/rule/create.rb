# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module Rule
        class Create < ::Mutations::BaseMutation
          graphql_name 'CreateContainerRegistryProtectionRule'
          description 'Creates a protection rule to restrict access to a project\'s container registry. ' \
                      'Available only when feature flag `container_registry_protected_containers` is enabled.'

          include FindsProject

          authorize :admin_container_image

          argument :project_path,
            GraphQL::Types::ID,
            required: true,
            description: 'Full path of the project where a protection rule is located.'

          argument :repository_path_pattern,
            GraphQL::Types::String,
            required: true,
            description:
              'Container repository path pattern protected by the protection rule. ' \
              'For example `my-project/my-container-*`. Wildcard character `*` allowed.'

          argument :push_protected_up_to_access_level,
            Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
            required: true,
            description:
              'Max GitLab access level to prevent from pushing container images to the container registry. ' \
              'For example `DEVELOPER`, `MAINTAINER`, `OWNER`.'

          argument :delete_protected_up_to_access_level,
            Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
            required: true,
            description:
              'Max GitLab access level to prevent from deleting container images in the container registry. ' \
              'For example `DEVELOPER`, `MAINTAINER`, `OWNER`.'

          field :container_registry_protection_rule,
            Types::ContainerRegistry::Protection::RuleType,
            null: true,
            description: 'Container registry protection rule after mutation.'

          def resolve(project_path:, **kwargs)
            project = authorized_find!(project_path)

            if Feature.disabled?(:container_registry_protected_containers, project)
              raise_resource_not_available_error!("'container_registry_protected_containers' feature flag is disabled")
            end

            response = ::ContainerRegistry::Protection::CreateRuleService.new(project, current_user, kwargs).execute

            { container_registry_protection_rule: response.payload[:container_registry_protection_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
