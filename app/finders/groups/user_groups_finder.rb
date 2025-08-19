# frozen_string_literal: true

# Groups::UserGroupsFinder
#
# Used to filter Groups where a user is member
#
# Arguments:
#   current_user - user requesting group info on target user
#   target_user - user for which groups will be found
#   params:
#     permissions: string (see Types::Groups::UserPermissionsEnum)
#     search: string used for search on path and group name
#     sort: string (see Types::Namespaces::GroupSortEnum)
#     exact_matches_first: boolean used to enable priotization of exact matches
#
# Initially created to filter user groups and descendants where the user can create projects
module Groups
  class UserGroupsFinder < Base
    def initialize(current_user, target_user, params = {})
      @current_user = current_user
      @target_user = target_user
      @params = params
    end

    def execute
      return Group.none unless current_user&.can?(:read_user_groups, target_user)
      return Group.none if target_user.blank?

      items = by_permission_scope
      items = by_organization(items)

      # Search will perform an ORDER BY to ensure exact matches are returned first.
      return by_search(items, exact_matches_first: true) if exact_matches_first_enabled?

      items = by_search(items)
      sort(items)
    end

    private

    attr_reader :current_user, :target_user, :params

    def by_permission_scope
      if permission_scope_create_projects?
        Groups::AcceptingProjectCreationsFinder.new(target_user).execute # rubocop: disable CodeReuse/Finder
      elsif permission_scope_transfer_projects?
        Groups::AcceptingProjectTransfersFinder.new(target_user).execute # rubocop: disable CodeReuse/Finder
      elsif permission_scope_import_projects?
        Groups::AcceptingProjectImportsFinder.new(target_user).execute # rubocop: disable CodeReuse/Finder
      else
        target_user.groups
      end
    end

    def permission_scope_create_projects?
      params[:permission_scope] == :create_projects
    end

    def permission_scope_transfer_projects?
      params[:permission_scope] == :transfer_projects
    end

    def permission_scope_import_projects?
      params[:permission_scope] == :import_projects
    end

    def by_organization(items)
      return items unless params[:organization]

      items.in_organization(params[:organization])
    end

    def sort(items)
      return super unless params[:sort]

      if params[:sort] == :similarity && params[:search].present?
        return items.sorted_by_similarity_desc(params[:search])
      end

      items.sort_by_attribute(params[:sort])
    end

    def exact_matches_first_enabled?
      params[:exact_matches_first] && params[:search].present?
    end
  end
end
