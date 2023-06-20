# frozen_string_literal: true

# Finder for retrieving crm_organizations scoped to a group
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

      crm_organizations = root_group.crm_organizations
      crm_organizations = by_ids(crm_organizations)
      crm_organizations = by_search(crm_organizations)
      crm_organizations = by_state(crm_organizations)
      sort_crm_organizations(crm_organizations)
    end

    private

    def sort_crm_organizations(crm_organizations)
      return crm_organizations.sort_by_name unless @params.key?(:sort)
      return crm_organizations if @params[:sort].nil?

      field = @params[:sort][:field]
      direction = @params[:sort][:direction]
      crm_organizations.sort_by_field(field, direction)
    end

    def root_group
      strong_memoize(:root_group) do
        group = params[:group]&.root_ancestor

        next unless can?(@current_user, :read_crm_organization, group)

        group
      end
    end

    def by_search(crm_organizations)
      return crm_organizations unless search?

      crm_organizations.search(params[:search])
    end

    def by_state(crm_organizations)
      return crm_organizations unless state?

      crm_organizations.search_by_state(params[:state])
    end

    def by_ids(crm_organizations)
      return crm_organizations unless ids?

      crm_organizations.id_in(params[:ids])
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
