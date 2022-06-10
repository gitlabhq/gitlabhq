# frozen_string_literal: true

# Finder for retrieving organizations scoped to a group
#
# Arguments:
#   current_user - user performing the action. Must have the correct permission level for the group.
#   params:
#     group: Group, required
#     search: String, optional
#     state: CustomerRelations::OrganizationStateEnum, optional
module Crm
  class OrganizationsFinder
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    attr_reader :params, :current_user

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      return CustomerRelations::Organization.none unless root_group

      organizations = root_group.organizations
      organizations = by_search(organizations)
      organizations = by_state(organizations)
      organizations.sort_by_name
    end

    private

    def root_group
      strong_memoize(:root_group) do
        group = params[:group]&.root_ancestor

        next unless can?(@current_user, :read_crm_organization, group)

        group
      end
    end

    def by_search(organizations)
      return organizations unless search?

      organizations.search(params[:search])
    end

    def by_state(organizations)
      return organizations unless state?

      organizations.search_by_state(params[:state])
    end

    def search?
      params[:search].present?
    end

    def state?
      params[:state].present?
    end
  end
end
