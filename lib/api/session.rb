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
      auth = Gitlab::Auth.new
      user = auth.find(params[:email] || params[:login], params[:password])

      return unauthorized! unless user
      present user, with: Entities::UserLogin
    end
  end
end
