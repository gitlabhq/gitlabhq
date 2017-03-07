class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  layout 'profile'

  # Overriden from Doorkeeper::AuthorizationsController to
  # include the call to session.delete
  def new
    if pre_auth.authorizable?
      if skip_authorization? || matching_token?
        auth = authorization.authorize
        session.delete(:user_return_to)
        redirect_to auth.redirect_uri
      else
        render "doorkeeper/authorizations/new"
      end
    else
      render "doorkeeper/authorizations/error"
    end
  end
end
