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
      user, _ = Gitlab::Auth.find(
        params[:email] || params[:login],
        params[:password],
        project: nil,
        ip: request.ip
      )

      return unauthorized! unless user
      present user, with: Entities::UserLogin
    end
  end
end
