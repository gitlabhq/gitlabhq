# frozen_string_literal: true

class PersonalAccessTokensFinder
  attr_accessor :params

  delegate :build, :find, :find_by_id, :find_by_token, to: :execute

  def initialize(params = {}, current_user = nil)
    @params = params
    @current_user = current_user
  end

  def execute
    tokens = PersonalAccessToken.all
    tokens = by_current_user(tokens)
    tokens = by_user(tokens)
    tokens = by_users(tokens)
    tokens = by_impersonation(tokens)
    tokens = by_state(tokens)
    tokens = by_owner_type(tokens)
    tokens = by_revoked_state(tokens)
    tokens = by_created_before(tokens)
    tokens = by_created_after(tokens)
    tokens = by_expires_before(tokens)
    tokens = by_expires_after(tokens)
    tokens = by_last_used_before(tokens)
    tokens = by_last_used_after(tokens)
    tokens = by_search(tokens)
    tokens = by_organization(tokens)
    tokens = tokens.allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/436657")

    sort(tokens)
  end

  private

  attr_reader :current_user

  def by_current_user(tokens)
    return tokens if current_user.nil? || current_user.can_admin_all_resources?

    unless Ability.allowed?(current_user, :read_user_personal_access_tokens, params[:user])
      return PersonalAccessToken.none
    end

    tokens
  end

  def by_owner_type(tokens)
    case @params[:owner_type]
    when 'human'
      tokens.owner_is_human
    else
      tokens
    end
  end

  def by_user(tokens)
    return tokens unless @params[:user]

    tokens.for_user(@params[:user])
  end

  def by_users(tokens)
    return tokens unless @params[:users]

    tokens.for_users(@params[:users])
  end

  def sort(tokens)
    available_sort_orders = PersonalAccessToken.simple_sorts.keys

    return tokens unless available_sort_orders.include?(params[:sort])

    tokens.order_by(params[:sort])
  end

  def by_impersonation(tokens)
    case @params[:impersonation]
    when true
      tokens.with_impersonation
    when false
      tokens.without_impersonation
    else
      tokens
    end
  end

  def by_state(tokens)
    case @params[:state]
    when 'active'
      tokens.active
    when 'inactive'
      tokens.inactive
    else
      tokens
    end
  end

  def by_revoked_state(tokens)
    return tokens unless params.has_key?(:revoked)

    params[:revoked] ? tokens.revoked : tokens.not_revoked
  end

  def by_created_before(tokens)
    return tokens unless params[:created_before]

    tokens.created_before(params[:created_before])
  end

  def by_created_after(tokens)
    return tokens unless params[:created_after]

    tokens.created_after(params[:created_after])
  end

  def by_expires_before(tokens)
    return tokens unless params[:expires_before]

    tokens.expires_before(params[:expires_before])
  end

  def by_expires_after(tokens)
    return tokens unless params[:expires_after]

    tokens.expires_after(params[:expires_after])
  end

  def by_last_used_before(tokens)
    return tokens unless params[:last_used_before]

    tokens.last_used_before(params[:last_used_before])
  end

  def by_last_used_after(tokens)
    return tokens unless params[:last_used_after]

    tokens.last_used_after(params[:last_used_after])
  end

  def by_search(tokens)
    return tokens unless params[:search]

    tokens.search(params[:search])
  end

  def by_organization(tokens)
    return tokens unless params[:organization]
    return tokens unless Feature.enabled?('pat_organization_filter', current_user)

    tokens.for_organization(params[:organization])
  end
end
