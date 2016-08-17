module API
  # Users API
  class Session < Grape::API
    # Login to get token
    #
    # Parameters:
    #   login (*required) - user login
    #   email (*required) - user email
    #   password (required) - user password
    #
    # Example Request:
    #  POST /session
    post "/session" do
      user = Gitlab::Auth.find_with_user_password(params[:email] || params[:login], params[:password])

      return unauthorized! unless user
      return render_api_error!('401 Unauthorized. You have 2FA enabled. Please use a personal access token to access the API', 401) if user.two_factor_enabled?
      present user, with: Entities::UserLogin
    end
  end
end
