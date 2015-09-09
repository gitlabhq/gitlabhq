module Ci
  class UserSessionsController < Ci::ApplicationController
    before_filter :authenticate_user!, except: [:new, :callback, :auth]

    def show
      @user = current_user
    end

    def new
    end

    def auth
      redirect_to client.auth_code.authorize_url({
        redirect_uri: callback_ci_user_sessions_url,
        state: params[:state]
      })
    end

    def callback
      token = client.auth_code.get_token(params[:code], redirect_uri: callback_ci_user_sessions_url).token
      
      @user_session = Ci::UserSession.new
      user = @user_session.authenticate(access_token: token)

      if user && sign_in(user)
        return_to = get_ouath_state_return_to(params[:state])
        redirect_to(return_to || ci_root_path)
      else
        @error = 'Invalid credentials'
        render :new
      end
      
    end

    def destroy
      sign_out

      redirect_to new_ci_user_sessions_path
    end

    protected

    def client
      @client ||= ::OAuth2::Client.new(
        GitlabCi.config.gitlab_server.app_id,
        GitlabCi.config.gitlab_server.app_secret,
        {
          site: GitlabCi.config.gitlab_server.url,
          authorize_url: 'oauth/authorize',
          token_url: 'oauth/token'
        }
      )
    end
  end
end
