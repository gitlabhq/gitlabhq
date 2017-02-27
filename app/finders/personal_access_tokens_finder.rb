class PersonalAccessTokensFinder
  attr_accessor :params

  def initialize(params = {})
    @params = params
  end

  def execute(token: nil, id: nil)
    tokens = by_impersonation

    return tokens.find_by_token(token) if token
    return tokens.find_by_id(id) if id

    tokens = by_state(tokens)
    tokens.order(@params[:order]) if @params[:order]

    tokens
  end

  private

  def personal_access_tokens
    @params[:user] ? @params[:user].personal_access_tokens : PersonalAccessToken.all
  end

  def by_impersonation
    case @params[:impersonation]
    when true
      personal_access_tokens.with_impersonation
    when false
      personal_access_tokens.without_impersonation
    else
      personal_access_tokens
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
