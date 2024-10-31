# frozen_string_literal: true

# UsersFinder
#
# Used to filter users by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     username: string
#     extern_uid: string
#     provider: string
#     search: string
#     active: boolean
#     admins: boolean
#     blocked: boolean
#     humans: boolean
#     external: boolean
#     non_external: boolean
#     without_active: boolean
#     without_humans: boolean
#     without_projects: boolean
#     sort: string
#     id: integer
#     non_internal: boolean
#
class UsersFinder
  include CreatedAtFilter
  include CustomAttributesFilter

  attr_accessor :current_user, :params

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    users = base_scope
    users = by_username(users)
    users = by_id(users)
    users = by_admins(users)
    users = by_humans(users)
    users = by_without_humans(users)
    users = by_search(users)
    users = by_blocked(users)
    users = by_active(users)
    users = by_without_active(users)
    users = by_external_identity(users)
    users = by_external(users)
    users = by_non_external(users)
    users = by_2fa(users)
    users = by_created_at(users)
    users = by_without_projects(users)
    users = by_custom_attributes(users)
    users = by_non_internal(users)
    users = by_without_project_bots(users)

    order(users)
  end

  private

  def base_scope
    group = params[:group]

    if group
      raise Gitlab::Access::AccessDeniedError unless user_can_read_group?(group)

      scope = ::Autocomplete::GroupUsersFinder.new(group: group).execute # rubocop: disable CodeReuse/Finder -- For SQL optimization sake we need to scope out group members first see: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137647#note_1664081899
    else
      scope = current_user&.can_admin_all_resources? ? User.all : User.without_forbidden_states
    end

    scope.order_id_desc
  end

  def by_username(users)
    return users unless params[:username]

    users.by_username(params[:username])
  end

  def by_id(users)
    return users unless params[:id]

    users.id_in(params[:id])
  end

  def by_admins(users)
    return users unless params[:admins] && current_user&.can_read_all_resources?

    users.admins
  end

  def by_humans(users)
    return users unless params[:humans]

    users.human
  end

  def by_without_humans(users)
    return users unless params[:without_humans]

    users.without_humans
  end

  def by_search(users)
    return users unless params[:search].present?

    users.search(
      params[:search],
      with_private_emails: current_user&.can_admin_all_resources?,
      use_minimum_char_limit: params[:use_minimum_char_limit]
    )
  end

  def by_blocked(users)
    return users unless params[:blocked]

    users.blocked
  end

  def by_active(users)
    return users unless params[:active]

    users.active
  end

  def by_without_active(users)
    return users unless params[:without_active]

    users.without_active
  end

  def by_external_identity(users)
    return users unless params[:extern_uid] && params[:provider]

    users.by_provider_and_extern_uid(params[:provider], params[:extern_uid])
  end

  def by_external(users)
    return users unless params[:external]

    users.external
  end

  def by_non_external(users)
    return users unless params[:non_external]

    users.non_external
  end

  def by_2fa(users)
    case params[:two_factor]
    when 'enabled'
      users.with_two_factor
    when 'disabled'
      users.without_two_factor
    else
      users
    end
  end

  def by_without_projects(users)
    return users unless params[:without_projects]

    users.without_projects
  end

  def by_non_internal(users)
    return users unless params[:non_internal]

    users.non_internal
  end

  def by_without_project_bots(users)
    return users unless params[:without_project_bots]

    users.without_project_bot
  end

  def order(users)
    return users unless params[:sort]

    users.order_by(params[:sort])
  end

  def user_can_read_group?(group)
    Ability.allowed?(current_user, :read_group, group)
  end
end

UsersFinder.prepend_mod_with('UsersFinder')
