module Gitlab
  # Users API
  class Session < Grape::API
    # Login to get token
    #
    # Example Request:
    #  POST /session
    post "/session" do
      resource = User.find_for_database_authentication(email: params[:email])

      return unauthorized! unless resource

      if resource.valid_password?(params[:password])
        present resource, with: Entities::UserLogin
      else
        unauthorized!
      end
    end
  end
end
