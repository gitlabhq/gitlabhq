# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationUserType < BaseObject
      graphql_name 'OrganizationUser'
      description 'A user with access to the organization.'

      include UsersHelper

      authorize :read_organization_user

      alias_method :organization_user, :object

      field :badges,
        [::Types::Organizations::OrganizationUserBadgeType],
        null: true,
        description: 'Badges describing the user within the organization.',
        alpha: { milestone: '16.4' }
      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the organization user.',
        alpha: { milestone: '16.4' }
      field :user,
        ::Types::UserType,
        null: false,
        description: 'User that is associated with the organization.',
        alpha: { milestone: '16.4' }

      def badges
        user_badges_in_admin_section(organization_user.user)
      end
    end
  end
end
