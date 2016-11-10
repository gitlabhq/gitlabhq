module API
  class Session < Grape::API
    desc 'Login to get token' do
      success Entities::UserLogin
    end
    params do
      optional :login, type: String, desc: 'The username'
      optional :email, type: String, desc: 'The email of the user'
      requires :password, type: String, desc: 'The password of the user'
      at_least_one_of :login, :email
    end
    post "/session" do
      user = Gitlab::Auth.find_with_user_password(params[:email] || params[:login], params[:password])

      return unauthorized! unless user
      return render_api_error!('401 Unauthorized. You have 2FA enabled. Please use a personal access token to access the API', 401) if user.two_factor_enabled?
      present user, with: Entities::UserLogin
    end
  end
end
