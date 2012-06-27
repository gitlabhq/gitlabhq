require 'api/entities'
require 'api/helpers'

module Gitlab
  class API < Grape::API
    format :json
    helpers APIHelpers

    resource :users do
      before { authenticate! }

      # GET /users
      get do
        @users = User.all
        present @users, :with => Entities::User
      end

      # GET /users/:id
      get ":id" do
        @user = User.find(params[:id])
        present @user, :with => Entities::User
      end
    end

    # GET /user
    get "/user" do
      authenticate!
      present @current_user, :with => Entities::User
    end
  end
end
