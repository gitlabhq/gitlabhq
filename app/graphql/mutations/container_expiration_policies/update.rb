# frozen_string_literal: true

module Mutations
  module ContainerExpirationPolicies
    class Update < Mutations::BaseMutation
      include ResolvesProject

      graphql_name 'UpdateContainerExpirationPolicy'

      authorize :destroy_container_image

      argument :project_path,
               GraphQL::ID_TYPE,
               required: true,
               description: 'The project path where the container expiration policy is located'

      argument :enabled,
               GraphQL::BOOLEAN_TYPE,
               required: false,
               description: copy_field_description(Types::ContainerExpirationPolicyType, :enabled)

      argument :cadence,
               Types::ContainerExpirationPolicyCadenceEnum,
               required: false,
               description: copy_field_description(Types::ContainerExpirationPolicyType, :cadence)

      argument :older_than,
               Types::ContainerExpirationPolicyOlderThanEnum,
               required: false,
               description: copy_field_description(Types::ContainerExpirationPolicyType, :older_than)

      argument :keep_n,
               Types::ContainerExpirationPolicyKeepEnum,
               required: false,
               description: copy_field_description(Types::ContainerExpirationPolicyType, :keep_n)

      field :container_expiration_policy,
            Types::ContainerExpirationPolicyType,
            null: true,
            description: 'The container expiration policy after mutation'

      def resolve(project_path:, **args)
        project = authorized_find!(full_path: project_path)

        result = ::ContainerExpirationPolicies::UpdateService
          .new(container: project, current_user: current_user, params: args)
          .execute

        {
          container_expiration_policy: result.payload[:container_expiration_policy],
          errors: result.errors
        }
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end
    end
  end
end
