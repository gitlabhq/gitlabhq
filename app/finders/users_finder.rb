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
#     blocked: boolean
#     external: boolean
#     non_external: boolean
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
    users = User.all.order_id_desc
    users = by_username(users)
    users = by_id(users)
    users = by_admins(users)
    users = by_search(users)
    users = by_blocked(users)
    users = by_active(users)
    users = by_external_identity(users)
    users = by_external(users)
    users = by_non_external(users)
    users = by_2fa(users)
    users = by_created_at(users)
    users = by_without_projects(users)
    users = by_custom_attributes(users)
    users = by_non_internal(users)

    order(users)
  end

  private

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

  def by_search(users)
    return users unless params[:search].present?

    users.search(params[:search])
  end

  def by_blocked(users)
    return users unless params[:blocked]

    users.blocked
  end

  def by_active(users)
    return users unless params[:active]

    users.active
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_external_identity(users)
    return users unless current_user&.admin? && params[:extern_uid] && params[:provider]

    users.joins(:identities).merge(Identity.with_extern_uid(params[:provider], params[:extern_uid]))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_external(users)
    return users unless params[:external]

    users.external
  end
  # rubocop: enable CodeReuse/ActiveRecord

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

  # rubocop: disable CodeReuse/ActiveRecord
  def order(users)
    return users unless params[:sort]

    users.order_by(params[:sort])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

UsersFinder.prepend_mod_with('UsersFinder')
