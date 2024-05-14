# frozen_string_literal: true

module Organizations
  class OrganizationAssociationCounter
    include ActionView::Helpers::NumberHelper
    include NumbersHelper

    COUNTER_LIMIT = 1000

    # @param organization [Organizations::Organization]
    # @param current_user [User]
    def initialize(organization:, current_user:)
      @organization = organization
      @current_user = current_user
    end

    def execute
      return {} if organization.nil? || !authorized?

      association_counts
    end

    private

    attr_reader :organization, :current_user

    def association_counts
      {
        groups: with_limited_counter(Group.in_organization(organization)),
        projects: with_limited_counter(Project.in_organization(organization)),
        users: with_limited_counter(OrganizationUser.in_organization(organization))
      }
    end

    def authorized?
      Ability.allowed?(current_user, :admin_organization, organization)
    end

    def with_limited_counter(resource)
      limited_counter_with_delimiter(resource, limit: COUNTER_LIMIT)
    end
  end
end
