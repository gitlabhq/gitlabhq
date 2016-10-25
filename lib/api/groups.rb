module API
  # groups API
  class Groups < Grape::API
    before { authenticate! }

    resource :groups do
      # Get a groups list
      #
      # Parameters:
      #   skip_groups (optional) - Array of group ids to exclude from list
      #   all_available (optional, boolean) - Show all group that you have access to
      # Example Request:
      #  GET /groups
      get do
        @groups = if current_user.admin
                    Group.all
                  elsif params[:all_available]
                    GroupsFinder.new.execute(current_user)
                  else
                    current_user.groups
                  end

        @groups = @groups.search(params[:search]) if params[:search].present?
        @groups = @groups.where.not(id: params[:skip_groups]) if params[:skip_groups].present?
        @groups = paginate @groups
        present @groups, with: Entities::Group
      end

      # Get list of owned groups for authenticated user
      #
      # Example Request:
      #   GET /groups/owned
      get '/owned' do
        @groups = current_user.owned_groups
        @groups = paginate @groups
        present @groups, with: Entities::Group, user: current_user
      end

      # Create group. Available only for users who can create groups.
      #
      # Parameters:
      #   name (required)                   - The name of the group
      #   path (required)                   - The path of the group
      #   description (optional)            - The description of the group
      #   visibility_level (optional)       - The visibility level of the group
      #   lfs_enabled (optional)            - Enable/disable LFS for the projects in this group
      #   request_access_enabled (optional) - Allow users to request member access
      # Example Request:
      #   POST /groups
      post do
        authorize! :create_group
        required_attributes! [:name, :path]

        attrs = attributes_for_keys [:name, :path, :description, :visibility_level, :lfs_enabled, :request_access_enabled]
        @group = Group.new(attrs)

        if @group.save
          @group.add_owner(current_user)
          present @group, with: Entities::Group
        else
          render_api_error!("Failed to save group #{@group.errors.messages}", 400)
        end
      end

      # Update group. Available only for users who can administrate groups.
      #
      # Parameters:
      #   id (required)                     - The ID of a group
      #   path (optional)                   - The path of the group
      #   description (optional)            - The description of the group
      #   visibility_level (optional)       - The visibility level of the group
      #   lfs_enabled (optional)            - Enable/disable LFS for the projects in this group
      #   request_access_enabled (optional) - Allow users to request member access
      # Example Request:
      #   PUT /groups/:id
      put ':id' do
        group = find_group(params[:id])
        authorize! :admin_group, group

        attrs = attributes_for_keys [:name, :path, :description, :visibility_level, :lfs_enabled, :request_access_enabled]

        if ::Groups::UpdateService.new(group, current_user, attrs).execute
          present group, with: Entities::GroupDetail
        else
          render_validation_error!(group)
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
        projects = GroupProjectsFinder.new(group).execute(current_user)
        projects = paginate projects
        present projects, with: Entities::Project, user: current_user
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
