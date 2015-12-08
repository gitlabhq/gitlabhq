module API
  # groups API
  class Groups < Grape::API
    before { authenticate! }

    resource :groups do
      # Get a groups list
      #
      # Example Request:
      #  GET /groups
      get do
        @groups = if current_user.admin
                    Group.all
                  else
                    current_user.groups
                  end

        @groups = @groups.search(params[:search]) if params[:search].present?
        @groups = paginate @groups
        present @groups, with: Entities::Group
      end

      # Create group. Available only for users who can create groups.
      #
      # Parameters:
      #   name (required) - The name of the group
      #   path (required) - The path of the group
      # Example Request:
      #   POST /groups
      post do
        authorize! :create_group, current_user
        required_attributes! [:name, :path]

        attrs = attributes_for_keys [:name, :path, :description]
        @group = Group.new(attrs)

        if @group.save
          @group.add_owner(current_user)
          present @group, with: Entities::Group
        else
          render_api_error!("Failed to save group #{@group.errors.messages}", 400)
        end
      end

      # Get a single group, with containing projects
      #
      # Parameters:
      #   id (required) - The ID of a group
      # Example Request:
      #   GET /groups/:id
      get ":id" do
        group = find_group(params[:id])
        present group, with: Entities::GroupDetail
      end

      # Remove group
      #
      # Parameters:
      #   id (required) - The ID of a group
      # Example Request:
      #   DELETE /groups/:id
      delete ":id" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        DestroyGroupService.new(group, current_user).execute
      end

      # Get a list of projects in this group
      #
      # Example Request:
      #   GET /groups/:id/projects
      get ":id/projects" do
        group = find_group(params[:id])
        projects = group.projects
        projects = filter_projects(projects)
        projects = paginate projects
        present projects, with: Entities::Project
      end

      # Transfer a project to the Group namespace
      #
      # Parameters:
      #   id - group id
      #   project_id  - project id
      # Example Request:
      #   POST /groups/:id/projects/:project_id
      post ":id/projects/:project_id" do
        authenticated_as_admin!
        group = Group.find_by(id: params[:id])
        project = Project.find(params[:project_id])
        result = ::Projects::TransferService.new(project, current_user).execute(group)

        if result
          present group
        else
          render_api_error!("Failed to transfer project #{project.errors.messages}", 400)
        end
      end
    end
  end
end
