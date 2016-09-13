module API
  # Users API
  class Session < Grape::API
    desc 'Login to get token' do
      success Entities::UserLogin
    end
    params do
      optional :login, type: String, desc: 'The username'
      optional :email, type: String, desc: 'The users email'
      exactly_one_of :login, :email

      required :password, type: String, desc: 'The users password'
    end
    post "/session" do
      user = Gitlab::Auth.find_with_user_password(params[:email] || params[:login], params[:password])

      unauthorized! unless user

      if user.two_factor_enabled?
        render_api_error!('401 Unauthorized. You have 2FA enabled. Please use a personal access token to access the API', 401)
      else
        present user, with: Entities::UserLogin
      end
    end
  end
end
