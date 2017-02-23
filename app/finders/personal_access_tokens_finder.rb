class PersonalAccessTokensFinder
  def initialize(user, params = {})
    @user = user
    @params = params
  end

  def execute
    pat_id = token_id?
    personal_access_tokens = @user.personal_access_tokens
    personal_access_tokens = personal_access_tokens.impersonation if impersonation?

    return find_token_by_id(personal_access_tokens, pat_id) if pat_id

    case state?
    when 'active'
      personal_access_tokens.active
    when 'inactive'
      personal_access_tokens.inactive
    else
      personal_access_tokens
    end
  end

  private

  def state?
    @params[:state].presence
  end

  def impersonation?
    @params[:impersonation].presence
  end

  def token_id?
    @params[:personal_access_token_id].presence
  end

  def find_token_by_id(personal_access_tokens, pat_id)
    personal_access_tokens.find_by(id: pat_id)
  end
end
