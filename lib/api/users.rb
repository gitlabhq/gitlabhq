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
        @users = paginate User
        present @users, with: Entities::User
      end

      # Get a single user
      #
      # Parameters:
      #   id (required) - The ID of a user
      # Example Request:
      #   GET /users/:id
      get ":id" do
        @user = User.find(params[:id])
        present @user, with: Entities::User
      end

      # Create user. Available only for admin
      #
      # Parameters:
      #   email (required)                  - Email
      #   password (required)               - Password
      #   name                              - Name
      #   skype                             - Skype ID
      #   linkedin                          - Linkedin
      #   twitter                           - Twitter account
      #   projects_limit                    - Number of projects user can create
      # Example Request:
      #   POST /users
      post do
        authenticated_as_admin!
        attrs = attributes_for_keys [:email, :name, :password, :skype, :linkedin, :twitter, :projects_limit, :username]
        user = User.new attrs, as: :admin
        if user.save
          present user, with: Entities::User
        else
          not_found!
        end
      end
    end

    resource :user do
      # Get currently authenticated user
      #
      # Example Request:
      #   GET /user
      get do
        present @current_user, with: Entities::User
      end

      # Get currently authenticated user's keys
      #
      # Example Request:
      #   GET /user/keys
      get "keys" do
        present current_user.keys, with: Entities::SSHKey
      end

      # Get single key owned by currently authenticated user
      #
      # Example Request:
      #   GET /user/keys/:id
      get "keys/:id" do
        key = current_user.keys.find params[:id]
        present key, with: Entities::SSHKey
      end

      # Add new ssh key to currently authenticated user
      #
      # Parameters:
      #   key (required) - New SSH Key
      #   title (required) - New SSH Key's title
      # Example Request:
      #   POST /user/keys
      post "keys" do
        attrs = attributes_for_keys [:title, :key]
        key = current_user.keys.new attrs
        if key.save
          present key, with: Entities::SSHKey
        else
          not_found!
        end
      end

      # Delete existed ssh key of currently authenticated user
      #
      # Parameters:
      #   id (required) - SSH Key ID
      # Example Request:
      #   DELETE /user/keys/:id
      delete "keys/:id" do
        key = current_user.keys.find params[:id]
        key.delete
      end
    end
  end
end
