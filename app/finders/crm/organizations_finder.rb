# frozen_string_literal: true

# Finder for retrieving organizations scoped to a group
#
# Arguments:
#   current_user - user performing the action. Must have the correct permission level for the group.
#   params:
#     group: Group, required
#     search: String, optional
#     state: CustomerRelations::OrganizationStateEnum, optional
#     ids: int[], optional
module Crm
  class OrganizationsFinder
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    attr_reader :params, :current_user

    def self.counts_by_state(current_user, params = {})
      params = params.merge(sort: nil)
      new(current_user, params).execute.counts_by_state
    end

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      return CustomerRelations::Organization.none unless root_group

      organizations = root_group.organizations
      organizations = by_ids(organizations)
      organizations = by_search(organizations)
      organizations = by_state(organizations)
      sort_organizations(organizations)
    end

    private

    def sort_organizations(organizations)
      return organizations.sort_by_name unless @params.key?(:sort)
      return organizations if @params[:sort].nil?

      field = @params[:sort][:field]
      direction = @params[:sort][:direction]
      organizations.sort_by_field(field, direction)
    end

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

    def by_ids(organizations)
      return organizations unless ids?

      organizations.id_in(params[:ids])
    end

    def search?
      params[:search].present?
    end

    def state?
      params[:state].present?
    end

    def ids?
      params[:ids].present?
    end
  end
end
