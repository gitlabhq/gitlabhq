require 'api/entities'
require 'api/helpers'

module Gitlab
  class API < Grape::API
    format :json
    helpers APIHelpers

    # Users API
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

    # Projects API
    resource :projects do
      before { authenticate! }

      # GET /projects
      get do
        @projects = current_user.projects
        present @projects, :with => Entities::Project
      end

      # GET /projects/:id
      get ":id" do
        @project = current_user.projects.find_by_code(params[:id])
        present @project, :with => Entities::Project
      end

      # GET /projects/:id/repository/branches
      get ":id/repository/branches" do
        @project = current_user.projects.find_by_code(params[:id])
        present @project.repo.heads.sort_by(&:name), :with => Entities::ProjectRepositoryBranches
      end

      # GET /projects/:id/repository/tags
      get ":id/repository/tags" do
        @project = current_user.projects.find_by_code(params[:id])
        present @project.repo.tags.sort_by(&:name).reverse, :with => Entities::ProjectRepositoryTags
      end
    end
  end
end
