module Gitlab
  # Users API
  class Users < Grape::API
    before { authenticate! }

    resource :users do
      # Get a users list
      #
      # Example Request:
      #  GET /users
      get do
        @users = User.all
        present @users, :with => Entities::User
      end

      # Get a single user
      #
      # Parameters:
      #   id (required) - The ID of a user
      # Example Request:
      #   GET /users/:id
      get ":id" do
        @user = User.find(params[:id])
        present @user, :with => Entities::User
      end
    end

    # Get currently authenticated user
    #
    # Example Request:
    #   GET /user
    get "/user" do
      present @current_user, :with => Entities::User
    end
  end
end
