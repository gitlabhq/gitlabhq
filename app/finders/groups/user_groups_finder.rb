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
#
# Initially created to filter user groups and descendants where the user can create projects
module Groups
  class UserGroupsFinder
    def initialize(current_user, target_user, params = {})
      @current_user = current_user
      @target_user = target_user
      @params = params
    end

    def execute
      return Group.none unless current_user&.can?(:read_user_groups, target_user)
      return Group.none if target_user.blank?

      items = by_permission_scope
      items = by_search(items)

      sort(items)
    end

    private

    attr_reader :current_user, :target_user, :params

    def sort(items)
      items.order(Group.arel_table[:path].asc, Group.arel_table[:id].asc) # rubocop: disable CodeReuse/ActiveRecord
    end

    def by_search(items)
      return items if params[:search].blank?

      items.search(params[:search])
    end

    def by_permission_scope
      if permission_scope_create_projects?
        target_user.manageable_groups(include_groups_with_developer_maintainer_access: true)
      elsif permission_scope_transfer_projects?
        target_user.manageable_groups(include_groups_with_developer_maintainer_access: false)
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
  end
end
