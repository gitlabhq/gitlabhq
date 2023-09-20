# frozen_string_literal: true

# Organizations::GroupsFinder
#
# Used to find Groups within an Organization
module Organizations
  class GroupsFinder
    # @param organization [Organizations::Organization]
    # @param current_user [User]
    # @param params [{ sort: { field: [String], direction: [String] }, search: [String] }]
    def initialize(organization:, current_user:, params: {})
      @organization = organization
      @current_user = current_user
      @params = params
    end

    def execute
      return Group.none if organization.nil? || !authorized?

      filter_groups(all_accessible_groups)
        .then { |groups| sort(groups) }
        .then(&:with_route)
    end

    private

    attr_reader :organization, :params, :current_user

    def all_accessible_groups
      current_user.authorized_groups.in_organization(organization)
    end

    def filter_groups(groups)
      by_search(groups)
    end

    def by_search(groups)
      return groups unless params[:search].present?

      groups.search(params[:search])
    end

    def sort(groups)
      return default_sort_order(groups) if params[:sort].blank?

      field = params[:sort][:field]
      direction = params[:sort][:direction]
      groups.reorder(field => direction) # rubocop: disable CodeReuse/ActiveRecord
    end

    def default_sort_order(groups)
      groups.sort_by_attribute('name_asc')
    end

    def authorized?
      Ability.allowed?(current_user, :read_organization, organization)
    end
  end
end
