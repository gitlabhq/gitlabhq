# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationUserType < BaseObject
      graphql_name 'OrganizationUser'
      description 'A user with access to the organization.'

      include ::UsersHelper

      authorize :read_organization_user

      alias_method :organization_user, :object

      expose_permissions Types::PermissionTypes::OrganizationUser

      field :access_level,
        ::Types::Organizations::OrganizationUserAccessLevelType,
        null: false,
        description: 'Access level of the user in the organization.',
        experiment: { milestone: '16.11' },
        method: :access_level_before_type_cast
      field :badges,
        [::Types::Organizations::OrganizationUserBadgeType],
        null: true,
        description: 'Badges describing the user within the organization.',
        experiment: { milestone: '16.4' }
      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the organization user.',
        experiment: { milestone: '16.4' }
      field :is_last_owner,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the user is the last owner of the organization.',
        experiment: { milestone: '16.11' },
        method: :last_owner?
      field :user,
        ::Types::UserType,
        null: false,
        description: 'User that is associated with the organization.',
        experiment: { milestone: '16.4' }

      def badges
        user_badges_in_admin_section(organization_user.user)
      end
    end
  end
end
