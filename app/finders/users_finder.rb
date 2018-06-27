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
    users = by_search(users)
    users = by_blocked(users)
    users = by_active(users)
    users = by_external_identity(users)
    users = by_external(users)
    users = by_2fa(users)
    users = by_created_at(users)
    users = by_custom_attributes(users)

    users
  end

  private

  def by_username(users)
    return users unless params[:username]

    users.where(username: params[:username])
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

  def by_external_identity(users)
    return users unless current_user&.admin? && params[:extern_uid] && params[:provider]

    users.joins(:identities).merge(Identity.with_extern_uid(params[:provider], params[:extern_uid]))
  end

  def by_external(users)
    return users = users.where.not(external: true) unless current_user&.admin?
    return users unless params[:external]

    users.external
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
end
