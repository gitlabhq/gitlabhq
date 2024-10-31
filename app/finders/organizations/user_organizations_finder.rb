# frozen_string_literal: true

module Organizations
  class UserOrganizationsFinder
    def initialize(current_user, target_user, params = {})
      @current_user = current_user
      @target_user = target_user
      @params = params
    end

    def execute
      return Organizations::Organization.none unless can_read_user_organizations?
      return Organizations::Organization.none if target_user.blank?

      by_search(organizations)
    end

    private

    attr_reader :current_user, :target_user, :params

    def organizations
      params[:solo_owned] ? target_user.solo_owned_organizations : target_user.organizations
    end

    def can_read_user_organizations?
      current_user&.can?(:read_user_organizations, target_user)
    end

    def by_search(items)
      params[:search].present? ? items.search(params[:search]) : items
    end
  end
end
