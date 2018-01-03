class PersonalAccessTokensFinder
  attr_accessor :params

  delegate :build, :find, :find_by, to: :execute

  def initialize(params = {})
    @params = params
  end

  def execute
    tokens = PersonalAccessToken.all
    tokens = by_user(tokens)
    tokens = by_impersonation(tokens)
    by_state(tokens)
  end

  private

  def by_user(tokens)
    return tokens unless @params[:user]

    tokens.where(user: @params[:user])
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
end
