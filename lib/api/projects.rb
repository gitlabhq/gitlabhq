module Gitlab
  # Projects API
  class Projects < Grape::API
    before { authenticate! }

    resource :projects do
      # Get a projects list for authenticated user
      #
      # Example Request:
      #   GET /projects
      get do
        @projects = current_user.projects
        present @projects, :with => Entities::Project
      end

      # Get a single project
      #
      # Parameters:
      #   id (required) - The code of a project
      # Example Request:
      #   GET /projects/:id
      get ":id" do
        @project = current_user.projects.find_by_code(params[:id])
        present @project, :with => Entities::Project
      end

      # Get a project repository branches
      #
      # Parameters:
      #   id (required) - The code of a project
      # Example Request:
      #   GET /projects/:id/repository/branches
      get ":id/repository/branches" do
        @project = current_user.projects.find_by_code(params[:id])
        present @project.repo.heads.sort_by(&:name), :with => Entities::ProjectRepositoryBranches
      end

      # Get a project repository tags
      #
      # Parameters:
      #   id (required) - The code of a project
      # Example Request:
      #   GET /projects/:id/repository/tags
      get ":id/repository/tags" do
        @project = current_user.projects.find_by_code(params[:id])
        present @project.repo.tags.sort_by(&:name).reverse, :with => Entities::ProjectRepositoryTags
      end
    end
  end
end
