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

    sort(tokens)
  end

  private

  attr_reader :current_user

  def by_current_user(tokens)
    return tokens if current_user.nil? || current_user.admin?
    return PersonalAccessToken.none unless Ability.allowed?(current_user, :read_user_personal_access_tokens, params[:user])

    tokens
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
    when 'active_or_expired'
      tokens.not_revoked.expired.or(tokens.active)
    else
      tokens
    end
  end
end
