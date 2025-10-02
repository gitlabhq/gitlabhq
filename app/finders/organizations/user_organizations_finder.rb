# frozen_string_literal: true

module Organizations
  class UserOrganizationsFinder < OrganizationsFinder
    def initialize(current_user, target_user, params = {})
      super(current_user, params)

      @target_user = target_user
    end

    def execute
      return Organizations::Organization.none unless can_read_user_organizations?
      return Organizations::Organization.none if target_user.blank?

      super
    end

    private

    attr_reader :current_user, :target_user

    def base_scope
      params[:solo_owned] ? target_user.solo_owned_organizations : target_user.organizations
    end

    def can_read_user_organizations?
      current_user&.can?(:read_user_organizations, target_user)
    end
  end
end
