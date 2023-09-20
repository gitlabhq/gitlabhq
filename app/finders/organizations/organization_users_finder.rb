# frozen_string_literal: true

# Organizations::OrganizationUsersFinder
#
# Used to find Users of an Organization
module Organizations
  class OrganizationUsersFinder
    # @param organization [Organizations::Organization]
    # @param current_user [User]
    def initialize(organization:, current_user:)
      @organization = organization
      @current_user = current_user
    end

    def execute
      return User.none if organization.nil? || !authorized?

      all_organization_users
    end

    private

    attr_reader :organization, :current_user

    def all_organization_users
      organization.organization_users
    end

    def authorized?
      Ability.allowed?(current_user, :read_organization_user, organization)
    end
  end
end
