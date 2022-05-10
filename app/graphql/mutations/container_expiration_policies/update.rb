# frozen_string_literal: true

module Mutations
  module ContainerExpirationPolicies
    class Update < Mutations::BaseMutation
      graphql_name 'UpdateContainerExpirationPolicy'

      include FindsProject

      authorize :admin_container_image

      argument :project_path,
               GraphQL::Types::ID,
               required: true,
               description: 'Project path where the container expiration policy is located.'

      argument :enabled,
               GraphQL::Types::Boolean,
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

      argument :name_regex,
               Types::UntrustedRegexp,
               required: false,
               description: copy_field_description(Types::ContainerExpirationPolicyType, :name_regex)

      argument :name_regex_keep,
               Types::UntrustedRegexp,
               required: false,
               description: copy_field_description(Types::ContainerExpirationPolicyType, :name_regex_keep)

      field :container_expiration_policy,
            Types::ContainerExpirationPolicyType,
            null: true,
            description: 'Container expiration policy after mutation.'

      def resolve(project_path:, **args)
        project = authorized_find!(project_path)

        result = ::ContainerExpirationPolicies::UpdateService
          .new(container: project, current_user: current_user, params: args)
          .execute

        {
          container_expiration_policy: result.payload[:container_expiration_policy],
          errors: result.errors
        }
      end
    end
  end
end
