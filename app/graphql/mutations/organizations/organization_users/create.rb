# frozen_string_literal: true

module Mutations
  module Organizations
    module OrganizationUsers
      class Create < BaseMutation
        graphql_name 'OrganizationUserCreate'

        authorize :create_organization_user
        authorize_granular_token permissions: :create_organization_user, boundary: :instance, boundary_type: :instance

        argument :organization_id,
          Types::GlobalIDType[::Organizations::Organization],
          required: true,
          description: 'ID of the organization to add the user to.'

        argument :username,
          GraphQL::Types::String,
          required: false,
          description: 'Username of the user to add to the organization.'

        argument :email,
          GraphQL::Types::String,
          required: false,
          description: 'Email of the user to add to the organization.'

        argument :user_type,
          ::Types::Organizations::OrganizationUserTypeEnum,
          required: true,
          description: 'Type to add the organization user with.'

        field :organization_user,
          ::Types::Organizations::OrganizationUserType,
          null: true,
          description: 'Organization user added by the mutation.',
          experiment: { milestone: '19.3' }

        validates exactly_one_of: [:username, :email]

        def resolve(organization_id:, **args)
          organization = find_organization(organization_id)

          verify_rate_limit!

          result = ::Organizations::OrganizationUsers::CreateService.new(
            organization,
            current_user: current_user,
            params: args
          ).execute

          { organization_user: result.payload[:organization_user], errors: result.errors }
        end

        private

        def verify_rate_limit!
          return unless Gitlab::ApplicationRateLimiter.throttled?(:organization_user_create, scope: [current_user])

          raise_resource_not_available_error! _('This endpoint has been requested too many times. Try again later.')
        end

        def find_organization(organization_id)
          organization = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(organization_id))

          raise_resource_not_available_error! unless organization

          authorize!(organization.organization_users.new)

          organization
        end
      end
    end
  end
end
